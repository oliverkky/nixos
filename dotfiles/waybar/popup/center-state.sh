#!/usr/bin/env bash

set -u

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/waybar"
weather_cache="$cache_dir/weather.txt"
mkdir -p "$cache_dir" 2>/dev/null || true

json_escape() {
    local text="${1//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    printf '%s' "$text"
}

media_title="Nothing playing"
media_artist=""
media_status="Stopped"
if command -v playerctl >/dev/null 2>&1; then
    media_status="$(playerctl status 2>/dev/null || printf Stopped)"
    if [[ "$media_status" != "Stopped" ]]; then
        media_title="$(playerctl metadata --format '{{ title }}' 2>/dev/null || printf 'Unknown title')"
        media_artist="$(playerctl metadata --format '{{ artist }}' 2>/dev/null || true)"
    fi
fi

events="No upcoming events"
if command -v khal >/dev/null 2>&1; then
    events="$(khal list today 7d 2>/dev/null | sed '/^[[:space:]]*$/d' | head -n 4 || true)"
elif command -v gcalcli >/dev/null 2>&1; then
    events="$(gcalcli agenda --nostarted --tsv 2>/dev/null | head -n 4 || true)"
fi
[[ -n "$events" ]] || events="No upcoming events"

weather="Forecast unavailable"
if [[ -r "$weather_cache" ]] && [[ $(( $(date +%s) - $(stat -c %Y "$weather_cache" 2>/dev/null || printf 0) )) -lt 1800 ]]; then
    weather="$(cat "$weather_cache")"
elif command -v curl >/dev/null 2>&1; then
    weather="$(curl -fsS --max-time 2 'https://wttr.in/?format=%l:+%c+%t,+%C,+%w' 2>/dev/null || true)"
    if [[ -n "$weather" ]]; then
        printf '%s\n' "$weather" >"$weather_cache" 2>/dev/null || true
    else
        weather="Forecast unavailable"
    fi
fi

printf '{'
printf '"media":{"status":"%s","title":"%s","artist":"%s"},' \
    "$(json_escape "$media_status")" \
    "$(json_escape "$media_title")" \
    "$(json_escape "$media_artist")"
printf '"events":"%s",' "$(json_escape "$events")"
printf '"weather":"%s"' "$(json_escape "$weather")"
printf '}\n'
