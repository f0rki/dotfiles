# Global Config.fish

source $__fish_config_dir/colors.fish

# prettify less
set -x LESS_TERMCAP_mb (echo -e '\x1b[01;31m')
set -x LESS_TERMCAP_md (echo -e '\x1b[01;38;5;74m')
set -x LESS_TERMCAP_me (echo -e '\x1b[0m')
set -x LESS_TERMCAP_se (echo -e '\x1b[0m')
set -x LESS_TERMCAP_so (echo -e '\x1b[38;5;246m')
set -x LESS_TERMCAP_ue (echo -e '\x1b[0m')
set -x LESS_TERMCAP_us (echo -e '\x1b[04;38;5;146m')

#### env vars ###

set -x EDITOR nvim


#### setup PATH
fish_add_path -a "$HOME/.local/bin/"
fish_add_path -p "$HOME/bin/"

# go tools
set -x GOPATH "$HOME/.go/"
fish_add_path -a "$GOPATH/bin/"

# rust tools
fish_add_path -a "$HOME/.cargo/bin/"

# flatpak
fish_add_path -a "/var/lib/flatpak/exports/bin/"
fish_add_path -a "$HOME/.local/share/flatpak/exports/bin/"
set -x XDG_DATA_DIRS "$XDG_DATA_DIRS:/usr/share/:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share"


#### host specific stuff ####
set -x HOST_SPECIFIC_CONFIG_LOADED False
set -l hostname_l (hostname|cut -d . -f 1)
set -l custom_config "$__fish_config_dir/hosts/$hostname_l.fish"
if test -e $custom_config
    source "$custom_config"
end

#### os specific stuff ####
set -l os (string lower (uname))
set -l os_fish_config "$__fish_config_dir/$os.fish"
if test -e "$os_fish_config"
    source $os_fish_config
end


#### set up ssh and gpg agent ####

if status --is-interactive
    set -l IFS
    # invoke keychain only on non-gnome environments and only if it is
    # available
    if command -v keychain >/dev/null 2>/dev/null && test "$XDG_CURRENT_DESKTOP" != GNOME && test "$XDG_CURRENT_DESKTOP" != KDE
        if test (uname) = Darwin; and command -v keychain >/dev/null 2>/dev/null
            eval (env SHELL=fish keychain --eval --inherit any-once -Q --quiet --agents ssh id_ed25519.github)
        else
            eval (env SHELL=fish keychain --systemd --eval --ssh-allow-forwarded -Q --quiet id_ed25519)
            if command -v gpg-agent >/dev/null 2>/dev/null; and not test -e /run/user/$(id -u)/gnupg/S.gpg-agent
                gpg-agent --daemon 2>/dev/null >/dev/null; or true
            end
        end
    end
end

#### set up zoxide for approximate cd'ing

if command -v zoxide 2>/dev/null >/dev/null
    zoxide init --cmd c fish | source
    function cf --description "cd zoxide/fzf"
        cd (zoxide query -l $argv | fzf)
    end
else
    alias c=cd
end

#### custom functions definitions ####

# workaround for/from https://github.com/fish-shell/fish-shell/issues/238
function forkand --description "Run a fish command in the background using a subshell"
    bash -c "fish -c '""$argv""' &"
end

function l
    ls -l $argv
end

function lsr
    ls -tr $argv
end

function ipy
    command ipython $argv
end

function mkcd --description "make directory and cd into it"
    mkdir -p $argv[1]
    cd $argv[1]
end


function xxd.orig
    command /usr/bin/xxd $argv
end

function xxd --description "hexdump utility (uses hexyl if available/sensible)"
    # use hexyl only when there are no other arguments, i.e., reverse xxd or
    # something else xxd specific
    if command -v hexyl >/dev/null 2>/dev/null; and test (count $argv) -le 1
        hexyl --color=always $argv
    else
        command xxd -g 1 $argv
    end
end

function ip
    command ip --color $argv
end

function git
    set -l oldshell $SHELL
    set -x SHELL (which bash)
    command git $argv
    set -l status_git $status
    set -x SHELL $oldshell
    return $status_git
end

function quickhttpshare -d "shares the current directory over HTTP on port 8080"
    if command -v static-web-server
        static-web-server -d . -p 8080 -z
    else
        python3 -m http.server 8080
    end
end

function sshproxy
    if test (count $argv) -ge 1
        set host $argv[1]
    else
        echo "error provide host as argv[1]"
    end
    if test (count $argv) -eq 2
        set port $argv[2]
    else
        set port 22022
    end
    echo "starting socks proxy via ssh to $host:$port"
    ssh -N -D $port $host
    return $status
end


function wttr -d "show weather from wttr.in"
    if test (count $argv) -eq 1
        curl "wttr.in/$argv[1]"
    else
        curl wttr.in
    end
end

function wttrk -d "show weather from wttr.in/cologne"
    wttr cologne
end

function AAAA -d "print a bunch of 'A' chars"
    if test (count $argv) -ge 1
        python -c "print('A' * sum(map(int, \"$argv[1..-1]\".split(' '))))"
    else
        echo "usage: AAAA <number>..."
    end
end

#function clean_shutdown -d "clean shutdown via awesome wm"
#    echo "clean_shutdown()" | awesome-client
#end

function chrome -d "launch chrome or chromium or whatever"
    if command -v google-chrome 2>/dev/null >/dev/null
        google-chrome --new-window $argv
    else if test -x /opt/google/chrome/chrome
        /opt/google/chrome/chrome --new-window $argv
    else if command -v chromium 2>/dev/null >/dev/null
        chromium --new-window $argv
    else if command -v org.chromium.Chromium 2>/dev/null >/dev/null
        org.chromium.Chromium --new-window $argv
    else if command -v flatpak; and flatpak info org.chromium.Chromium 2>/dev/null >/dev/null
        flatpak run org.chromium.Chromium --new-windows $argv
    else
        echo "There seems to be no chrome|chromium installed!"
        if command -v notify-send >/dev/null 2>/dev/null;
            notify-send "(No chrome|chromium found)"
        end
        return 1
    end
end


set -gx CTRT ""

if command -v podman >/dev/null
    set -g CTRT podman

    function container-clean
        echo "[podman/buildah full cleanup]"
        echo "[podman]"
        echo "Removing containers"
        podman rm (podman ps -aq)
        echo "Removing container images"
        podman rmi (podman images -aq)
        echo "pruning images"
        podman image prune -f
        echo "[buildah]"
        echo "Removing containers"
        buildah rm (buildah ps -aq)
        echo "Removing container images"
        buildah rmi (buildah images -aq)
        echo "pruning images [podman] again"
        podman image prune -f
    end

else if command -v docker >/dev/null;
    set -g CTRT "docker"

    if id -nG | grep -qw "docker"
        # all good we can run docker directly
        true
    else
        # assume we have sudo rights and wrap docker
        set -g CTRT "sudo docker"
        function docker -d "docker with sudo wrapper"
            command sudo docker $argv
        end
    end

    function container-clean -d "remove all containers"
        echo "[docker cleanup]"
        docker rm (docker ps -aq)
        docker rmi (docker images -aq)
        docker system prune
    end
else if command -v finch >/dev/null;
    set -g CTRT "finch"

    function container-clean -d "remove all containers"
        echo "[finch cleanup]"
        finch rm (finch ps -aq)
        finch rmi (finch images -aq)
        finch system prune
    end
end

function container-enter --description "enter container in current pwd"
    if test -z "$CTRT";
        echo "[ERROR] no container runtime installed!"
        return -1
    end
    # needed only on fedora due to SELinux, but doesn't hurt on others
    set volflag ":z"
    if test (uname) = Darwin;
        set volflag ""
    end

    command $CTRT run --rm -it -v (pwd):(pwd)$volflag -w (pwd) $argv
    return $status
end


if test -n "$CTRT";
    # common container launchers
    source $__fish_config_dir/common/containers.fish
end

function cloc
    if command -v tokei 2>/dev/null >/dev/null
        #echo "WARNING: using tokei instead of cloc for faster counting" >&2
        command tokei $argv
    else
        command cloc $argv
    end
end

function fetchgitignore
    echo "===== use git gen-ignore instead! ====="
    git gen-ignore $argv[1]

    # old:
    #curl https://raw.githubusercontent.com/github/gitignore/master/$argv[1].gitignore >> .gitignore
end

function ssh
    # remote server might not recognize our actual hipster TERM
    command env TERM=xterm-256color (command -v ssh) $argv
end


function vagrant
    env TERM=xterm-256color vagrant $argv
end


function qpdf-merge -d "merge multiple pdfs; output file is the first arg"
    command qpdf --empty --pages $argv[2..] -- $argv[1]
end

## remarkable
function rmstream -d "stream remarkable framebuffer over ssh"
    set -l width 1408
    set -l height 1872
    set -l bytes_per_pixel 2
    set -l loop_wait true
    set -l loglevel info

    set -l compress /opt/bin/zstd
    set -l decompress zstd -d

    # calculte how much bytes the window is
    set -l window_bytes (math "$width*$height*$bytes_per_pixel")
    # rotate 90 degrees if landscape
    #set -l landscape_param ""
    if test (count $argv) -ge 1; and test "$argv[1]" = -l; or test "$argv[1]" = --landscape
        echo "landscape!"
        set landscape_param -vf transpose=3,hflip
    end
    # read the first $window_bytes of the framebuffer
    set -l head_fb0 "dd if=/dev/fb0 count=1 bs=$window_bytes 2>/dev/null"
    # loop that keeps on reading and compressing, to be executed remotely
    set -l read_loop "while $head_fb0; do $loop_wait; done | $compress"
    echo "Starting Streaming"
    command ssh remarkable "$read_loop" \
        | $decompress \
        | ffplay -vcodec rawvideo \
        -loglevel "$loglevel" \
        -f rawvideo \
        -pixel_format gray16le \
        -video_size "$width,$height" \
        $landscape_param \
        -i -
end

# alias p2r="docker run --rm -v \"${HOME}/.rmapi:/home/user/.rmapi:rw\" p2r"
if ! command -v p2r >/dev/null 2>/dev/null
    function p2r
        set -f rmapi_home "$HOME/.config/rmapi"
        if test (uname) = Darwin;
            # TODO: podman on macos doesn't like the space in the path for
            # volumes?
            # set -f rmapi_home = "$HOME/Library/Application Support/rmapi"
        end

        if test -z (command $CTRT images -q paper2remarkable)
            for dir in ~/pkg/containers/paper2remarkable
                if test -d "$dir"
                    pushd "$dir"
                    git pull
                    command $CTRT build -t paper2remarkable .
                    popd
                    break
                end
            end
        end
        command $CTRT run \
            --net=host \
            --rm -it \
            -v (pwd):(pwd) -w (pwd) \
            -v "$rmapi_home":/root/.config/rmapi:rw \
            --security-opt label=disable \
            paper2remarkable $argv
    end
end

# quick cheat.sh lookup :)
function cheat.sh
    curl cheat.sh/$argv
end


function load_dotenv -d "quick and dirty loader  for .env files in fish shell"
  for line in (grep -v '^#' .env)
    set item (string split -m 1 '=' $line)
    set -gx $item[1] $item[2]
    echo "Exported key $item[1]"
  end
end

function rr-cargo-test -d "run cargo test with rr record"
    # workaround from:
    # https://github.com/rust-lang/cargo/issues/6821#issuecomment-479971235

    if test (sysctl -n kernel.perf_event_paranoid) -ne 1
        echo "need to lower perf_event_paranoid to 1"
        sudo sysctl -w kernel.perf_event_paranoid=1
    end

    echo "[+] launching 'rr record' for 'cargo test $argv'"
    env RUST_BACKTRACE=full \
        CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_RUNNER="rr record" \
        cargo test $argv
    echo "[+] starting rr replay"
    rr replay -d rust-gdb
end

# deprecated.
# function neovim-headless-update -d "update neovim plugins etc."
#     nvim --headless -c 'PlugInstall --sync' -c 'qa'
#     nvim --headless -c 'UpdateRemotePlugins' -c 'qa'
#     nvim --headless -c 'TSInstallSync! rust c cpp python lua bash' -c 'qa'
# end

function clear-gnome-recent-files -d "clear gnome's recently used files"
    rm ~/.local/share/recently-used.xbel
end

## apps running in chrom(e|ium)

function whatsapp -d "launch chrom(e|ium) with whatsapp"
    chrome 'https://web.whatsapp.com'
end

if command -v claude >/dev/null 2>/dev/null
    if command -v bwrap >/dev/null 2>/dev/null
        source $__fish_config_dir/common/claude-bwrap.fish
    else if command -v nono >/dev/null 2>/dev/null
        source $__fish_config_dir/common/claude-nono.fish
    end
end

## include flatpak apps aliases

if test (uname) != Darwin; and command -v flatpak >/dev/null 2>/dev/null
    source $__fish_config_dir/common/flatpakapps.fish
end

## END
