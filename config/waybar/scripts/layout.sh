#!/usr/bin/env bash

swaymsg \
  --type get_inputs | \
  jq \
    --raw-output \ '
      [
        .[] |
          select(.type == "keyboard") |
          .xkb_active_layout_name |
          select(contains("English (US)") | not)
      ] |
        first // "English" |
        sub(" \\(US\\)"; "") |
        sub("English"; "EN") |
        sub("German"; "DE")
    '

swaymsg \
  --type subscribe \
  --monitor \
  --raw \
  '["input"]' | \
  jq \
    --raw-output \
    --unbuffered \ '
      select(.change == "xkb_layout") |
        .input.xkb_active_layout_name |
        sub(" \\(US\\)"; "") |
        sub("English"; "EN") |
        sub("German"; "DE")
    '
