#!/usr/bin/env bash

set -euo pipefail

if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf '{"text":"󰂲","tooltip":"Bluetooth unavailable","class":"off"}\n'
    exit 0
fi

powered=$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')
if [ "$powered" != "yes" ]; then
    jq -cn --arg text "󰂲" --arg tooltip "Bluetooth off" --arg class "off" \
        '{text: $text, tooltip: $tooltip, class: $class}'
    exit 0
fi

connected=$(
    bluetoothctl devices Connected 2>/dev/null \
        | sed 's/^Device [^ ]* //' \
        | paste -sd ', ' -
)

if [ -n "$connected" ]; then
    jq -cn --arg text "󰂱" --arg tooltip "$connected" --arg class "connected" \
        '{text: $text, tooltip: $tooltip, class: $class}'
else
    jq -cn --arg text "󰂯" --arg tooltip "Bluetooth on" --arg class "on" \
        '{text: $text, tooltip: $tooltip, class: $class}'
fi
