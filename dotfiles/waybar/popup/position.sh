#!/usr/bin/env bash

set -u

mode="${1:-quick-settings}"
popup_pid="${2:-}"
action="${3:-open}"

if [[ "$mode" == "clock" ]]; then
    title='Waybar GNOME Clock'
    width=800
    height=590
    start_width=168
    start_height=30
else
    title='Waybar GNOME Quick Settings'
    width=360
    height=520
    start_width=126
    start_height=30
fi

get_monitor_json() {
    hyprctl -j monitors 2>/dev/null | jq -c 'map(select(.focused == true)) | .[0] // .[0]'
}

monitor_json="$(get_monitor_json)"

if [[ -n "$monitor_json" ]] && [[ "$monitor_json" != "null" ]]; then
    mon_x="$(jq -r '.x // 0' <<<"$monitor_json")"
    mon_y="$(jq -r '.y // 0' <<<"$monitor_json")"
    mon_w="$(jq -r '.width // 2560' <<<"$monitor_json")"
else
    mon_x=0
    mon_y=0
    mon_w=2560
fi

if [[ "$mode" == "clock" ]]; then
    start_x=$((mon_x + (mon_w - start_width) / 2))
    start_y=$((mon_y + 2))
    pos_x=$((mon_x + (mon_w - width) / 2))
    pos_y=$((mon_y + 30))
else
    start_x=$((mon_x + mon_w - start_width - 12))
    start_y=$((mon_y + 2))
    pos_x=$((mon_x + mon_w - width - 10))
    pos_y=$((mon_y + 26))
fi

for _ in $(seq 1 40); do
    sleep 0.1

    if [[ -n "$popup_pid" ]] && ! kill -0 "$popup_pid" 2>/dev/null; then
        exit 0
    fi

    if hyprctl -j clients 2>/dev/null | jq -e --arg title "$title" '.[] | select(.title == $title)' >/dev/null; then
        hyprctl dispatch resizewindowpixel exact "$start_width" "$start_height",title:^"${title}"$ >/dev/null 2>&1 || true
        hyprctl dispatch movewindowpixel exact "$start_x" "$start_y",title:^"${title}"$ >/dev/null 2>&1 || true
        if [[ "$action" == "close" ]]; then
            sleep 0.12
            exit 0
        fi
        sleep 0.08
        hyprctl dispatch resizewindowpixel exact "$width" "$height",title:^"${title}"$ >/dev/null 2>&1 || true
        hyprctl dispatch movewindowpixel exact "$pos_x" "$pos_y",title:^"${title}"$ >/dev/null 2>&1 || true
        exit 0
    fi
done
