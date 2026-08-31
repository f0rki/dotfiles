contains $PATH "/var/lib/flatpak/exports/bin/"; \
    or set -xp PATH "/var/lib/flatpak/exports/bin/"

# fedora specific function definitions
#
function ninja
    command ninja-build $argv
end

function sage
    command bash -l -c "sage $argv"
end

#function signal -d "launch signal desktop client"
#    chrome --profile-directory=Default --app-id=bikioccmkafdpakkkcpdbppfkghcmihk
#end

function __linklib
    if not test -L $argv[1]
        ln -s $argv[2] $argv[1]
    end
end

function binja -d 'start binary ninja with limited resources in the background'
    set BN ~/bin/binaryninja  
    forkand reslimit env LD_LIBRARY_PATH=$BN/plugins $BN/binaryninja $argv
    #forkand reslimit $BN/binaryninja $argv
    #forkand env LD_LIBRARY_PATH=$BN/plugins $BN/binaryninja $argv

    # using systemd-run
    #set -l cmd systemd-run --user --pty --same-dir --wait --collect --service-type=exec \
    #    -p MemoryMax=42G \
    #    -p IOWeight=1 \
    #    -p CPUWeight=1 \
    #    fish -c "$argv"
end


function tbrun
    command toolbox run -c dev-toolbox-fedora fish -c "$argv"
end

function tb --description=toolbox
    command toolbox $argv
end


function __fedora_silverblue_sys_upgrade
    set -l MARKER "[\033[93m+\033[0m]"

    #########################################################################
    printf "$MARKER updating system: rpm-ostree\n"
    sudo rpm-ostree upgrade
    
    #########################################################################
    printf "$MARKER checking for firmware updates\n"
    fwupdmgr update
    
    #########################################################################
    printf "$MARKER updating with flatpak\n"
    flatpak update -y
    flatpak uninstall --unused -y
    
    #########################################################################
    printf "$MARKER pulling new container with podman\n"
    for c in docker.io/hadolint/hadolint docker.io/tmknom/prettier docker.io/syncthing/syncthing docker.io/nixos/nix
        podman pull "$c"
    end

    systemctl --user stop nix-in-container-daemon
    nix-in-container-daemon

    #########################################################################
    printf "$MARKER updating default toolbox container\n"
    pushd ~/pkg/container/dev-toolbox-fedora/
    podman build --pull=always -t (basename (pwd)) .
    popd
    
    tbrun sudo dnf upgrade -y
    
    #########################################################################
    printf "$MARKER updating/installing with go get\n"
    
    # the embedded unipdf only works without -u :shrug:
    pushd ~/src/rmapi
    tbrun git pull
    tbrun go install
    popd
    
    #########################################################################
    printf "$MARKER rustup update\n"
    tbrun rustup update

    printf "$MARKER updating programs installed with cargo\n"
    tbrun cargo install \
        ripgrep_all \
        du-dust
    #cargo install --force --git https://github.com/latex-lsp/texlab.git
    
    #########################################################################
    #printf "$MARKER updating with pip --user\n"
    #tbrun pip install --user -U \
    #    pynvim \
    #    neovim-remote \
    #    yapf \
    #    pympress \
    #    pdfCropMargins \
    #    virtualfish
    
    printf "$MARKER updating neovim plugins\n"
    neovim-headless-update

    printf "$MARKER updating with pip --user\n"
    tbrun pip install --user -U \
       pdfCropMargins \
       paper2remarkable readabilipy
end
