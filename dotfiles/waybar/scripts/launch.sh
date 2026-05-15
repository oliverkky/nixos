#!/usr/bin/env bash

set -euo pipefail

pkill waybar || true
sleep 0.1

waybar \
    -c "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config/top.jsonc" \
    -s "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style/top.css" &

waybar \
    -c "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/config/splash.jsonc" \
    -s "${XDG_CONFIG_HOME:-$HOME/.config}/waybar/style/splash.css" &
