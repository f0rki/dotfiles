# homebrew env vars
set -gx HOMEBREW_PREFIX "/opt/homebrew";
set -gx HOMEBREW_CELLAR "/opt/homebrew/Cellar";
set -gx HOMEBREW_REPOSITORY "/opt/homebrew";
set -q MANPATH; or set MANPATH ''; set -gx MANPATH "/opt/homebrew/share/man" $MANPATH;
set -q INFOPATH; or set INFOPATH ''; set -gx INFOPATH "/opt/homebrew/share/info" $INFOPATH;


# setup PATH
set -q PATH; or set PATH ''; set -gx PATH "$HOME/.nix-profile/bin/" "/nix/var/nix/profiles/default/bin" "$HOME/.cargo/bin" "/opt/homebrew/bin" "/opt/homebrew/sbin" "$HOME/.local/bin" "/usr/local/bin/" $PATH;

set -gx SHELL (command -v fish)

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if command -v nvim >/dev/null
    set -gx EDITOR nvim
end


function sys_upgrade --description "Update the system with all the package managers"
    set -l MARKER "[\033[93m+\033[0m]"

    printf "$MARKER updating with mac os softwareupdate\n"
    softwareupdate -i -r
    
    if test -d ~/.config/nix-config/darwin;
        printf "$MARKER updating nix system flake\n"
        pushd ~/.config/nix-config/darwin
        # if nix flake update; and git add flake.lock; and git commit -m 'darwin flake lock update'
        #     sudo darwin-rebuild switch --flake . --show-trace
        # end
        just update
        popd
    end

    if command -v nix >/dev/null 2>/dev/null;
        printf "$MARKER updating nix profile\n"
        nix profile upgrade '.*'
    else
        # if there is no nix, there is likely brew.
        if command -v brew >/dev/null 2>/dev/null
            printf "$MARKER updating with brew\n"
            brew update
            brew upgrade
        end
    end

    if command -v rustup >/dev/null 2>/dev/null
        printf "$MARKER updating with rustup\n"
        rustup update
    end
end



# source $FISH_CONFIG_DIR/common/aws.fish
