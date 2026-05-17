#!/usr/bin/env bash

set -u

if ! command -v powerprofilesctl >/dev/null 2>&1; then
    exit 0
fi

current="$(powerprofilesctl get 2>/dev/null || printf balanced)"

case "$current" in
    power-saver)
        next="balanced"
        ;;
    balanced)
        next="performance"
        ;;
    performance)
        next="power-saver"
        ;;
    *)
        next="balanced"
        ;;
esac

powerprofilesctl set "$next" >/dev/null 2>&1 || true

"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/apply-power-profile-display" >/dev/null 2>&1 || true
