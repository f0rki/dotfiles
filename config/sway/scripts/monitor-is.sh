#!/usr/bin/env bash

set -eu

swaymsg bindsym ctrl+\$modkey+j "focus output $1"
swaymsg bindsym alt+\$modkey+j "exec swaymsg move output $1 && swaymsg focus output $1"
