if command -v bwrap >/dev/null 2>/dev/null;
    function x-claude-bwrapped -d "run a process within bubblewrap sandbox - intended for claude"
        set -l claude_path (realpath -e -- $argv[1])
        or return 127
        set -l rest $argv[2..]

        # split $argv on the first literal `--`
        set -l bwrap_args
        set -l claude_args
        set -l idx (contains -i -- -- $rest)
        if test -n "$idx"
            test $idx -gt 1; and set bwrap_args $rest[1..(math $idx - 1)]
            test $idx -lt (count $rest); and set claude_args $rest[(math $idx + 1)..]
        else
            set claude_args $rest
        end

        if test (realpath "$PWD") = (realpath "$HOME")
            echo "bwrap-check: refusing to run in $HOME directory"
            return 1
        end

        # Run Claude as the *normal* (non-root) user inside the sandbox. bwrap's
        # userns otherwise inherits uid 0 (pasta maps the login user to 0), and
        # Claude Code refuses --dangerously-skip-permissions when euid == 0. There
        # is no need for root in the NS; presenting the real uid also drops the
        # final process to CapEff=0. NB: this does NOT close the userns-LPE path
        # (a fresh `unshare -U -r` still grants full caps) -- that needs seccomp.
        set -l real_uid (id -u)
        set -l real_gid (id -g)
        if test "$real_uid" = 0
            echo "bwrap-check: WARNING launched as host root (uid 0); cannot drop to a" >&2
            echo "bwrap-check: WARNING non-root user in the sandbox, so --dangerously-skip-permissions" >&2
            echo "bwrap-check: WARNING (claude-yolo) will still be refused. Launch as a normal user." >&2
        end

        # ---------------------------------------------------------------
        # Hardening knobs (see SANDBOX-ASSESSMENT.md)
        #
        #   X_CLAUDE_NET        pasta | netns | none | host   (default: pasta)
        #       pasta  run bwrap inside a pasta(1) network namespace:
        #              Claude keeps outbound HTTPS, but the netns is fresh
        #              so host abstract sockets (X11 @/tmp/.X11-unix/X0,
        #              D-Bus, systemd) are NOT reachable. Closes the X11
        #              takeover that plain --share-net exposes.
        #       netns  join a persistent, systemd-managed netns ("claudenet")
        #              with veth+NAT and an nftables egress allowlist. NOT YET
        #              IMPLEMENTED -- see the detailed comment + TODO in the
        #              `case netns` branch below.
        #       none   --unshare-net: no network at all (most locked down).
        #       host   legacy --share-net: shares the HOST netns. Exposes
        #              the host X server and full LAN. Warned, opt-in only.
        #
        #   X_CLAUDE_SECCOMP    path to a compiled seccomp BPF -> --seccomp.
        #              Build it with gen-claude-seccomp.py. If unset, a filter at
        #              ~/.config/claude/seccomp.bpf is used automatically.
        #   X_CLAUDE_NEW_SESSION=1   add --new-session (blocks TIOCSTI tty
        #              injection; may affect Ctrl-C / interactive TUIs).
        # ---------------------------------------------------------------
        set -l net_mode $X_CLAUDE_NET
        test -z "$net_mode"; and set net_mode pasta
        if test "$net_mode" = pasta; and not command -v pasta >/dev/null 2>/dev/null
            echo "bwrap-check: pasta not found; falling back to X_CLAUDE_NET=none (no network)" >&2
            set net_mode none
        end

        # net-related bwrap flags
        set -l net_args
        switch $net_mode
            case pasta
                # pasta puts us in a fresh netns already; keep it (--share-net
                # here shares *pasta's* clean namespace, not the host's).
                set net_args --share-net
            case host
                echo "bwrap-check: WARNING X_CLAUDE_NET=host shares the HOST network namespace." >&2
                echo "bwrap-check: WARNING this exposes the host X server (@/tmp/.X11-unix) and LAN." >&2
                set net_args --share-net
            case netns
                # -----------------------------------------------------------
                # Persistent named netns + veth + NAT, managed by a systemd
                # service on the AppVM (the "system service" variant).
                #
                # Idea: instead of a per-launch userspace stack (pasta), set up
                # ONE persistent network namespace ("claudenet") at boot that
                # has real in-kernel connectivity via a veth pair + NAT. bwrap
                # then joins it with `ip netns exec claudenet bwrap ... --share-net`
                # (share-net keeps claudenet, NOT the host netns). Because it is
                # a fresh netns it carries none of the host's abstract sockets
                # (no @/tmp/.X11-unix X11 leak) and no host LAN visibility.
                #
                # Why bother when pasta already works:
                #   - real kernel networking (faster, no per-session daemon,
                #     no /dev/net/tun dependency inside the launch path);
                #   - you can attach an nftables EGRESS ALLOWLIST to the netns
                #     (permit only DNS + 443 to Anthropic; drop RFC1918 /
                #     link-local / 169.254 metadata). pasta gives a clean netns
                #     but no easy egress filtering. This is the real upgrade.
                #
                # TODO(revisit): implement this mode. Outline of the necessary
                # steps:
                #   1. systemd oneshot unit `claudenet.service` (RemainAfterExit)
                #      run at boot on the AppVM, ExecStart doing:
                #        a. ip netns add claudenet
                #        b. ip link add veth-claude type veth peer name veth-claude-ns
                #        c. ip link set veth-claude-ns netns claudenet
                #        d. host side:  ip addr add 10.55.0.1/30 dev veth-claude
                #                       ip link set veth-claude up
                #        e. ns side:    ip -n claudenet addr add 10.55.0.2/30 dev veth-claude-ns
                #                       ip -n claudenet link set veth-claude-ns up
                #                       ip -n claudenet link set lo up
                #                       ip -n claudenet route add default via 10.55.0.1
                #        f. DNS for the ns:  mkdir -p /etc/netns/claudenet
                #                            write nameserver (e.g. 10.55.0.1 or a
                #                            forwarder) to /etc/netns/claudenet/resolv.conf
                #        g. ExecStop reverses: ip netns del claudenet (+ veth cleanup)
                #      NOTE on Qubes: qubes-firewall may flush/own nftables and
                #      routing on this qube; hook setup after qubes-firewall or
                #      express egress policy via qvm-firewall instead of local nft.
                #   2. NAT + egress firewall on the AppVM (in claudenet.service or
                #      a paired unit), e.g. nftables:
                #        - masquerade 10.55.0.0/30 out the uplink;
                #        - forward chain: allow ct state est,rel; allow udp/tcp 53
                #          to the resolver; allow tcp 443 to Anthropic ranges;
                #          drop 10/8, 172.16/12, 192.168/16, 169.254/16; drop rest;
                #        - enable net.ipv4.ip_forward.
                #      (Tighten to L7/hostname by pointing 443 at a filtering
                #       proxy in the ns instead of open Anthropic ranges.)
                #   3. Ensure this launcher can enter the ns unprivileged:
                #      `ip netns exec` needs CAP_SYS_ADMIN, so either run the
                #      exec via a tiny setuid/sudo helper allowlisted for exactly
                #      `ip netns exec claudenet ...`, or use `nsenter --net=
                #      /run/netns/claudenet` behind an allowlisted sudo rule.
                #   4. Wire this case below: build `$net_ns_prefix` =
                #      (sudo) ip netns exec claudenet, set net_args to --share-net
                #      (keep the joined ns), and prepend $net_ns_prefix to the
                #      bwrap invocation in the dispatch block further down
                #      (mirroring how the `pasta` branch wraps $bwrap_cmd).
                #   5. Add a `claude-net-check` self-test: run curl -sS
                #      https://api.anthropic.com inside the sandbox to confirm
                #      egress works and that LAN/metadata are blocked.
                # -----------------------------------------------------------
                echo "bwrap-check: X_CLAUDE_NET=netns is not implemented yet (see TODO in this file)." >&2
                echo "bwrap-check: set up claudenet.service first, or use X_CLAUDE_NET=pasta." >&2
                return 1
            case none '*'
                set net_args # nothing -> --unshare-all leaves net unshared (empty netns)
        end

        # Non-root uid inside the sandbox (see the real_uid computation above).
        # bwrap ALWAYS owns its own user namespace (--unshare-user is implied by
        # --unshare-all), and as that namespace's creator it holds full caps for
        # mount setup regardless of its uid number. So it can map any inner uid
        # onto whatever single uid it inherits -- whether pasta hands it 0 or
        # `nobody` -- via --uid/--gid. (Verified: an unprivileged, nobody-only
        # userns still remaps its child to uid 1000.)
        #
        # This deliberately leaves pasta at its default: pasta stays UNPRIVILEGED
        # (nobody) *outside* the sandbox; only the process *inside* bwrap carries
        # the real uid. Forcing pasta itself to the real uid (via --runas) would
        # be backwards. File ownership still lines up: inner real_uid -> pasta's
        # uid -> host real_uid, so writes to ~/.claude etc. work.
        set -l uid_args --uid "$real_uid" --gid "$real_gid"

        # optional --new-session
        set -l session_args
        if test -n "$X_CLAUDE_NEW_SESSION"
            set session_args --new-session
        end

        set -l bind_pwd_args --bind "$PWD" "$PWD"
        if test "$X_CLAUDE_PWD_RO"
            set bind_pwd_args --ro-bind "$PWD" "$PWD"
        end

        # optional seccomp filter, passed on fd 4.
        # Compile the .bpf with gen-claude-seccomp.py (needs /usr/bin/python3 +
        # python3-libseccomp). If X_CLAUDE_SECCOMP is unset we look for a default
        set -l seccomp_file $X_CLAUDE_SECCOMP
        set -l default_seccomp_file "$__fish_config_dir/common/claude-bwrap-bpf/seccomp.bpf"
        if test -z "$seccomp_file"; and test -r "$default_seccomp_file"
            set seccomp_file "$default_seccomp_file" 
        end
        set -l seccomp_args
        if test -n "$seccomp_file"; and test -r "$seccomp_file"
            set seccomp_args --seccomp 4
        else
            echo "bwrap-check: seccomp filter '$seccomp_file' is not readable" >&2
            return 1
        end

        # The bwrap invocation, built once so we can optionally wrap it in pasta.
        set -l bwrap_cmd \
            bwrap \
            --proc /proc \
            --dev /dev \
            --tmpfs /dev/shm \
            --tmpfs /tmp \
            --ro-bind /usr /usr \
            --symlink usr/bin /bin \
            --symlink usr/sbin /sbin \
            --symlink usr/lib /lib \
            --symlink usr/lib64 /lib64 \
            --ro-bind /etc/passwd /etc/passwd \
            --ro-bind /etc/group /etc/group \
            --ro-bind /etc/resolv.conf /etc/resolv.conf \
            --ro-bind /etc/hosts /etc/hosts \
            --ro-bind /etc/ssl /etc/ssl \
            --ro-bind /etc/pki /etc/pki \
            --ro-bind /etc/crypto-policies /etc/crypto-policies \
            --ro-bind /nix /nix \
            --ro-bind "$seccomp_file" "$seccomp_file" \
            --ro-bind-try "$claude_path" "$claude_path" \
            --ro-bind-try "$HOME/.nix-profile" "$HOME/.nix-profile" \
            --ro-bind-try "$HOME/.gitconfig" "$HOME/.gitconfig" \
            --ro-bind-try "$HOME/.gitconfig.local" "$HOME/.gitconfig.local" \
            --ro-bind-try "$HOME/.local" "$HOME/.local" \
            --ro-bind-try "$HOME/.npm" "$HOME/.npm" \
            --ro-bind-try "$HOME/.cargo" "$HOME/.cargo" \
            --bind "$HOME/.claude" "$HOME/.claude" \
            --bind "$HOME/.claude.json" "$HOME/.claude.json" \
            $bind_pwd_args \
            --setenv HOME "$HOME" \
            --setenv USER "$USER" \
            --unsetenv DISPLAY \
            --unsetenv WAYLAND_DISPLAY \
            --unsetenv XAUTHORITY \
            --unsetenv DBUS_SESSION_BUS_ADDRESS \
            --unsetenv SSH_AUTH_SOCK \
            --unsetenv XDG_RUNTIME_DIR \
            $seccomp_args \
            $session_args \
            $uid_args \
            --disable-userns \
            --unshare-all \
            --unshare-user \
            $net_args \
            --die-with-parent \
            --chdir "$PWD" \
            $bwrap_args \
            -- $claude_path $claude_args

        if test "$net_mode" = pasta
            # Spawn bwrap inside a pasta-managed network namespace. pasta
            # configures outbound connectivity + DNS from the host default
            # route, but the namespace itself is fresh (no host abstract
            # sockets). --config-net sets up addresses/routes/DNS.
            if test -n "$seccomp_args"
                pasta --config-net -- sh -c "$bwrap_cmd 4<$seccomp_file"
            else
                pasta --config-net -- $bwrap_cmd
            end
        else
            if test -n "$seccomp_args"
                $bwrap_cmd 4<"$seccomp_file"
            else
                $bwrap_cmd
            end
        end
    end

    function claude -d "run claude in a sandbox" --wraps claude
        x-claude-bwrapped (command -v claude) $argv
    end

    function claude-yolo -d "run claude in a sandbox; yolo mode" --wraps claude
        set -p argv "--dangerously-skip-permissions"
        claude $argv
    end

    function claude-unsafe -d "run unsandboxed claude" --wraps claude
        command claude $argv
    end
end
