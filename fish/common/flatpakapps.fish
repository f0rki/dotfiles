
set -g _FLATPAK_ARGS --nofilesystem=home --nofilesystem=xdg-download

if test "$XDG_SESSION_TYPE" = "wayland"
    set -ga _FLATPAK_ARGS --socket=wayland
end

function spotify --description "flatpak run com.spotify.Client"
    # passing --socket=wayland seems to cause problems?
    flatpak run --nofilesystem=home --nofilesystem=xdg-download com.spotify.Client $argv
end

function signal --description "flatpak run org.signal.Signal"
    flatpak run $_FLATPAK_ARGS --filesystem=xdg-download org.signal.Signal $argv
end

function steam --description "flatpak run com.valvesoftware.Steam"
    flatpak run $_FLATPAK_ARGS --filesystem=xdg-download com.valvesoftware.Steam $argv
end

function slack --description "flatpak run com.slack.Slack"
    flatpak run $_FLATPAK_ARGS --filesystem=xdg-download com.slack.Slack $argv
end

function zoom --description "flatpak run us.zoom.Zoom"
    flatpak run $_FLATPAK_ARGS --nofilesystem=home us.zoom.Zoom $argv
end

function bitwarden --description "flatpak run com.bitwarden.desktop"
    flatpak run $_FLATPAK_ARGS com.bitwarden.desktop $argv
end

function vscode --description "flatpak run com.visualstudio.code"
    flatpak run $_FLATPAK_ARGS --filesystem=xdg-download com.visualstudio.code $argv
end

function discord --description "flatpak run com.discordapp.Discord"
    flatpak run  $_FLATPAK_ARGS --nofilesystem=home com.discordapp.Discord $argv
end

function drawio --description "flatpak run com.jgraph.drawio"
    flatpak run $_FLATPAK_ARGS --filesystem="$PWD" -v com.jgraph.drawio.desktop $argv
end
