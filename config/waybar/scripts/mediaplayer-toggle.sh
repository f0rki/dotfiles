#!/usr/bin/env bash

set -eu -o pipefail

if [[ "$(playerctl -l 2>&1)" == "No players were found" ]]; then
    systemctl --user start spotifyd
    sleep 1
    playerctl play
else
    # not yet properly supported by spotifyd/librespot...
    # playerctl play-pause
    if [[ "$(playerctl status)" == "Playing" ]]; then
        playerctl pause
    else
        playerctl play
    fi
fi
