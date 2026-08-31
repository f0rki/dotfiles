# Set up the per-user profile.
# This part should be kept in sync with nixpkgs:nixos/modules/programs/shell.nix

if test -d "$HOME/.nix-profile"; and test -d /nix

    set -l NIX_LINK "$HOME/.nix-profile"
    set -l NIX_USER_PROFILE_DIR /nix/var/nix/profiles/per-user/$USER

    # Append ~/.nix-defexpr/channels to $NIX_PATH so that <nixpkgs>
    # paths work when the user has fetched the Nixpkgs channel.
    set -l defexpr_path "$HOME/.nix-defexpr/channels"
    if test -e "$defexpr_path";
        contains $NIX_PATH "$defexpr_path"; or set -xp NIX_PATH "$defexpr_path"
    end

    # Set up environment.
    # This part should be kept in sync with nixpkgs:nixos/modules/programs/environment.nix
    set -x NIX_PROFILES "/nix/var/nix/profiles/default $HOME/.nix-profile"

    # Set $NIX_SSL_CERT_FILE so that Nixpkgs applications like curl work.
    if test -e /etc/ssl/certs/ca-certificates.crt ;  # NixOS, Ubuntu, Debian, Gentoo, Arch
        set -x NIX_SSL_CERT_FILE /etc/ssl/certs/ca-certificates.crt
    else if test -e /etc/ssl/ca-bundle.pem;  # openSUSE Tumbleweed
        set -x NIX_SSL_CERT_FILE /etc/ssl/ca-bundle.pem
    else if test -e /etc/ssl/certs/ca-bundle.crt;  # Old NixOS
        set -x NIX_SSL_CERT_FILE /etc/ssl/certs/ca-bundle.crt
    else if test -e /etc/pki/tls/certs/ca-bundle.crt;  # Fedora, CentOS
        set -x NIX_SSL_CERT_FILE /etc/pki/tls/certs/ca-bundle.crt
    else if test -e "$NIX_LINK/etc/ssl/certs/ca-bundle.crt";  # fall back to cacert in Nix profile
        set -x NIX_SSL_CERT_FILE "$NIX_LINK/etc/ssl/certs/ca-bundle.crt"
    else if test -e "$NIX_LINK/etc/ca-bundle.crt";  # old cacert in Nix profile
        set -x NIX_SSL_CERT_FILE "$NIX_LINK/etc/ca-bundle.crt"
    end

    set -xp MANPATH "/run/current-system/sw/share/man/:$MANPATH:$NIX_LINK/share/man"

    set -l path "$NIX_LINK/bin:$PATH"
    #if not contains $fish_user_paths "$path";
    #    set -Up fish_user_paths "$path"
    if not contains $PATH "$path";
        set -xp PATH "$path"
    end

    # So fedora uses a newer (2.31) glibc version, than nix. this results in
    # borked locale archives. this is the fix:
    # set -x LOCALE_ARCHIVE_2_30 (nix-build --no-out-link "<nixpkgs>" -A glibcLocales)"/lib/locale/locale-archive"
    # need to install the locales first though
    #
    # set -x LOCALE_ARCHIVE_2_30 (nix-build --no-out-link "<nixpkgs>" -A glibcLocales)"/lib/locale/locale-archive"
end

#### set up nix stuff ####

if command -v any-nix-shell >/dev/null 2>/dev/null
    any-nix-shell fish --info-right | source
end

function nix_sys_upgrade --description "update system, containers, tools etc."
    set -l MARKER "[\033[93m+\033[0m]"
    printf "$MARKER updating system with nixos-rebuild\n"
    sudo nix-channel --update
    sudo nixos-rebuild boot --upgrade
    
    printf "$MARKER updating user nix packages\n"
    #nix-env --upgrade
    nix profile upgrade
    
    printf "$MARKER flatpak update\n"
    flatpak update -y
    printf "$MARKER flatpak remove unused\n"
    flatpak uninstall --unused -y

    printf "$MARKER rustup update\n"
    rustup update
    
    printf "$MARKER updating neovim plugins\n"
    neovim-headless-update
end

function nix-develop-at --description 'Enter a nix develop shell for a flake elsewhere, dropped into fish, back in your original dir'
    if test (count $argv) -lt 1
        echo "Usage: nix-develop-at <path-to-flake> [extra nix develop args...]"
        return 1
    end

    set -l flake_dir $argv[1]
    set -l extra_args $argv[2..-1]
    set -l orig_dir $PWD

    if not cd $flake_dir
        echo "nix-develop-at: couldn't cd into $flake_dir"
        return 1
    end

    set -l cd_back "cd "(string escape -- $orig_dir)

    nix develop $extra_args --command fish --init-command $cd_back

    cd $orig_dir
end
