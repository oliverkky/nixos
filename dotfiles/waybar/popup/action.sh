#!/usr/bin/env bash

set -u

launch() {
    setsid -f "$@" >/dev/null 2>&1
}

launch_shell() {
    setsid -f sh -lc "$1" >/dev/null 2>&1
}

toggle_nm_radio() {
    local kind="$1"
    local state
    state="$(nmcli radio "$kind" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    if [[ "$state" == "enabled" ]]; then
        nmcli radio "$kind" off >/dev/null 2>&1
    else
        nmcli radio "$kind" on >/dev/null 2>&1
    fi
}

toggle_bluetooth() {
    local powered
    powered="$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')"
    if [[ "$powered" == "yes" ]]; then
        bluetoothctl power off >/dev/null 2>&1
    else
        bluetoothctl power on >/dev/null 2>&1
    fi
}

case "${1:-}" in
    screenshot)
        if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
            mkdir -p "$HOME/Pictures/Screenshots"
            file="$HOME/Pictures/Screenshots/$(date +%Y-%m-%d_%H-%M-%S).png"
            launch_shell "grim -g \"\$(slurp)\" \"$file\""
        fi
        ;;
    system-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch gnome-control-center
        ;;
    lock)
        loginctl lock-session >/dev/null 2>&1
        ;;
    power-menu)
        if command -v gnome-control-center >/dev/null 2>&1; then
            launch_shell 'gnome-control-center power || gnome-control-center'
        fi
        ;;
    volume)
        value="${2:-50}"
        command -v wpctl >/dev/null 2>&1 && wpctl set-volume @DEFAULT_AUDIO_SINK@ "$value%" >/dev/null 2>&1
        ;;
    toggle-mute)
        command -v wpctl >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1
        ;;
    toggle-wifi)
        command -v nmcli >/dev/null 2>&1 && toggle_nm_radio wifi
        ;;
    toggle-bluetooth)
        command -v bluetoothctl >/dev/null 2>&1 && toggle_bluetooth
        ;;
    set-power-mode)
        mode="${2:-balanced}"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set "$mode" >/dev/null 2>&1
        ;;
    toggle-night-light)
        if command -v gsettings >/dev/null 2>&1; then
            current="$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || true)"
            if [[ "$current" == "true" ]]; then
                gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled false >/dev/null 2>&1
            else
                gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true >/dev/null 2>&1
            fi
        fi
        ;;
    toggle-dark-style)
        if command -v gsettings >/dev/null 2>&1; then
            current="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
            if [[ "$current" == *"prefer-dark"* ]]; then
                gsettings set org.gnome.desktop.interface color-scheme prefer-light >/dev/null 2>&1
            else
                gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1
            fi
        fi
        ;;
    toggle-dnd)
        if command -v gsettings >/dev/null 2>&1; then
            current="$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null || true)"
            if [[ "$current" == "true" ]]; then
                gsettings set org.gnome.desktop.notifications show-banners false >/dev/null 2>&1
            else
                gsettings set org.gnome.desktop.notifications show-banners true >/dev/null 2>&1
            fi
        fi
        ;;
    network-settings)
        if command -v gnome-control-center >/dev/null 2>&1; then
            launch_shell 'gnome-control-center wifi || gnome-control-center network || gnome-control-center'
        elif command -v nm-connection-editor >/dev/null 2>&1; then
            launch nm-connection-editor
        fi
        ;;
    bluetooth-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center bluetooth || gnome-control-center'
        ;;
    power-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center power || gnome-control-center'
        ;;
    sound-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center sound || gnome-control-center'
        ;;
    calendar)
        command -v gnome-calendar >/dev/null 2>&1 && launch gnome-calendar
        ;;
    datetime-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center datetime || gnome-control-center'
        ;;
esac
