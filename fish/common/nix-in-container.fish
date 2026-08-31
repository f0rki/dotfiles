# this is primarily for fedora, where you can't have multi-user nix installed.
# TODO: do we want this also on nix-capable systems? 
if test -n "$CTRT"; and ! test -e /nix/
    function nix-in-container --description "run nix in a container"

        if test "$CTRT" = "podman"; and test -e "$HOME/.config/systemd/user/nix-in-container-daemon.service";
            # okay
            usyctl start nix-in-container-daemon.service; or true
        else if  test "$CTRT" = "docker"; or test "$CTRT" = "sudo docker";
            docker start nix-in-container-daemon; or true
        else
            echo "[WARNING] make sure nix-in-container-daemon container is running..."
        end

        set -l image "docker.io/nixos/nix"
        command "$CTRT" run \
            --security-opt label=disable \
            --rm -it \
                -e NIX_REMOTE=daemon \
                -v "$HOME/.nix-in-container/etc/nix/nix.conf:/etc/nix/nix.conf:ro" \
                -v "$HOME/.nix-in-container/store:/nix/store:ro" \
                -v "$HOME/.nix-in-container/var/nix/db:/nix/var/nix/db:ro" \
                -v "$HOME/.nix-in-container/var/nix/daemon-socket/socket:/nix/var/nix/daemon-socket/socket:ro" \
            -v (pwd):(pwd) -w (pwd) \
            "$image" $argv
                # -v "$HOME/.nix-in-container/var/nix/daemon-socket:/nix/var/nix/daemon-socket:ro,Z" \
    end

    function nix-in-container-daemon --description "create and run a nix-daemon in a container"
        set -l target "$HOME/.nix-in-container/"
        set -l image "docker.io/nixos/nix"

        mkdir -p "$target"
        mkdir -p "$target/var/"

        echo "create dummy container with nix contents"
        command "$CTRT" rm nix-dummy; or true
        command "$CTRT" create \
                --name nix-dummy \
                $image
                # --pull=always \
        echo "copying contents of nix store from container to host"
        if ! test -e "$target/etc/nix/nix.conf";
            mkdir -p $target/etc/nix/
            command "$CTRT" cp nix-dummy:"/etc/nix/nix.conf" "$target/etc/nix/nix.conf"
        end
        command "$CTRT" cp nix-dummy:"/nix/store" "$target/"
        command "$CTRT" cp nix-dummy:"/nix/var/nix" "$target/var/"
        command "$CTRT" rm nix-dummy

        echo "starting containerized nix daemon"
        command "$CTRT" rm nix-in-container-daemon; or true
        command "$CTRT" run \
                -d --name nix-in-container-daemon \
                -v "$HOME/.nix-in-container/etc/nix/nix.conf:/etc/nix/nix.conf:ro" \
                -v "$target/store:/nix/store" \
                -v "$target/var/nix/:/nix/var/nix/" \
                --security-opt label=disable \
                $image nix --extra-experimental-features nix-command --extra-experimental-features flakes daemon
        command "$CTRT" logs nix-in-container-daemon
    end

    if ! command -v nix; and ! command -v nix-shell;
        function nix --description "nix wrapped in container"
            nix-in-container nix $argv
        end
    end
    if ! command -v nix-shell >/dev/null 2>/dev/null;
        function nix-shell --description "nix wrapped in container"
            nix-in-container nix-shell $argv
        end
    end
end
