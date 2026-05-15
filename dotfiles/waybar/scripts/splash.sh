#!/usr/bin/env bash

set -euo pipefail

messages="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/splash_messages.conf"
fallback="Hello World!"

if [[ -r "$messages" ]]; then
    message="$(
        awk '
            /^[[:space:]]*($|#)/ { next }
            { lines[++count] = $0 }
            END {
                if (count > 0) {
                    srand()
                    print lines[int(rand() * count) + 1]
                }
            }
        ' "$messages"
    )"
else
    message=""
fi

if [[ -z "${message:-}" ]]; then
    message="$fallback"
fi

message="${message//\\/\\\\}"
message="${message//\"/\\\"}"
message="${message//$'\n'/ }"

printf '{"text":"%s","tooltip":"Hyprland splash replacement"}\n' "$message"
