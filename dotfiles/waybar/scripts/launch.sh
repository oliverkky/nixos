#!/usr/bin/env bash

set -euo pipefail

if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active graphical-session.target >/dev/null 2>&1; then
    systemctl --user restart waybar-top.service waybar-splash.service
    exit 0
fi

pkill waybar || true
sleep 0.1

waybar \
    -c "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config/top.jsonc" \
    -s "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style/top.css" &

waybar \
    -c "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config/splash.jsonc" \
    -s "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style/splash.css" &
