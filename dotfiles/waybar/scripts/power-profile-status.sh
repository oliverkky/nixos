#!/usr/bin/env bash

set -u

json_escape() {
    local text="${1//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    printf '%s' "$text"
}

mode="balanced"
label="Balanced"
icon="󰾅"

if command -v powerprofilesctl >/dev/null 2>&1; then
    mode="$(powerprofilesctl get 2>/dev/null || printf balanced)"
fi

case "$mode" in
    performance)
        label="Performance"
        icon="󰓅"
        ;;
    power-saver)
        label="Power Saver"
        icon="󰌪"
        ;;
esac

printf '{"text":"%s","tooltip":"Power profile: %s","class":"%s"}\n' \
    "$(json_escape "$icon")" \
    "$(json_escape "$label")" \
    "$(json_escape "$mode")"
