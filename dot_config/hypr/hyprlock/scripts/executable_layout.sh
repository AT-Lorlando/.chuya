#!/usr/bin/env bash

LAYOUT=$(hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n 1)

if [[ "$LAYOUT" == *"French"* ]]; then
    echo "FR"
elif [[ "$LAYOUT" == *"English (US)"* ]]; then
    echo "US"
else
    echo "${LAYOUT:0:3}"
fi
