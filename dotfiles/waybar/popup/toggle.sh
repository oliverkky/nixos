#!/usr/bin/env bash

set -u

config_root="${XDG_CONFIG_HOME:-$HOME/.config}"
mode="${1:-quick-settings}"
launch_mode="${2:-}"
popup_script="$config_root/waybar/popup/gnome_popup.js"
position_script="$config_root/waybar/popup/position.sh"
pid_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-gnome-popup"

mkdir -p "$pid_dir"

close_mode() {
    local target="$1"
    local pid_file="$pid_dir/${target}.pid"

    if [[ -f "$pid_file" ]]; then
        local pid
        pid="$(cat "$pid_file" 2>/dev/null || true)"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            "$position_script" "$target" "$pid" close >/dev/null 2>&1 || true
            kill "$pid" 2>/dev/null || true
        fi
        rm -f "$pid_file"
    fi
}

is_running() {
    local pid_file="$pid_dir/${mode}.pid"
    if [[ ! -f "$pid_file" ]]; then
        return 1
    fi

    local pid
    pid="$(cat "$pid_file" 2>/dev/null || true)"
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

if is_running; then
    close_mode "$mode"
    exit 0
fi

if [[ "$mode" == "clock" ]]; then
    close_mode "quick-settings"
else
    close_mode "clock"
fi

if [[ "$launch_mode" == "sticky" ]]; then
    WAYBAR_GNOME_POPUP_STICKY=1 gjs "$popup_script" "$mode" >/tmp/waybar-gnome-popup-"$mode".log 2>&1 &
else
    gjs "$popup_script" "$mode" >/tmp/waybar-gnome-popup-"$mode".log 2>&1 &
fi
popup_pid=$!
printf '%s\n' "$popup_pid" >"$pid_dir/${mode}.pid"

"$position_script" "$mode" "$popup_pid" &
