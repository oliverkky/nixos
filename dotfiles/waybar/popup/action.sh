#!/usr/bin/env bash

set -u

config_root="${XDG_CONFIG_HOME:-$HOME/.config}"

launch() {
    setsid -f "$@" >/dev/null 2>&1
}

launch_shell() {
    setsid -f sh -lc "$1" >/dev/null 2>&1
}

launch_config_script() {
    local script="$config_root/$1"
    if [[ -x "$script" ]]; then
        launch "$script"
    fi
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
        launch_config_script "rofi/scripts/control-screenshot"
        ;;
    system-settings)
        if command -v gnome-control-center >/dev/null 2>&1; then
            launch gnome-control-center
        elif command -v nwg-look >/dev/null 2>&1; then
            launch nwg-look
        fi
        ;;
    lock)
        if command -v hyprlock >/dev/null 2>&1; then
            launch hyprlock
        else
            loginctl lock-session >/dev/null 2>&1
        fi
        ;;
    power-menu)
        launch_config_script "rofi/scripts/control-session"
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
    disconnect-wifi)
        if command -v nmcli >/dev/null 2>&1; then
            device="$(nmcli -t -f DEVICE,TYPE dev status | awk -F: '$2 == "wifi" {print $1; exit}')"
            [[ -n "${device:-}" ]] && nmcli device disconnect "$device" >/dev/null 2>&1
        fi
        ;;
    network-menu)
        launch_config_script "rofi/scripts/control-network"
        ;;
    toggle-bluetooth)
        command -v bluetoothctl >/dev/null 2>&1 && toggle_bluetooth
        ;;
    bluetooth-menu)
        launch_config_script "rofi/scripts/control-bluetooth"
        ;;
    set-power-mode)
        mode="${2:-balanced}"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set "$mode" >/dev/null 2>&1
        "${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts/apply-power-profile-display" >/dev/null 2>&1 || true
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
        if [[ -x "$config_root/rofi/scripts/control-bluetooth" ]]; then
            launch "$config_root/rofi/scripts/control-bluetooth"
        elif command -v gnome-control-center >/dev/null 2>&1; then
            launch_shell 'gnome-control-center bluetooth || gnome-control-center'
        fi
        ;;
    power-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center power || gnome-control-center'
        ;;
    sound-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center sound || gnome-control-center'
        ;;
    audio-menu)
        launch_config_script "rofi/scripts/control-audio"
        ;;
    media-play-pause)
        command -v playerctl >/dev/null 2>&1 && playerctl play-pause >/dev/null 2>&1
        ;;
    media-next)
        command -v playerctl >/dev/null 2>&1 && playerctl next >/dev/null 2>&1
        ;;
    media-prev)
        command -v playerctl >/dev/null 2>&1 && playerctl previous >/dev/null 2>&1
        ;;
    calendar)
        if command -v gnome-calendar >/dev/null 2>&1; then
            launch gnome-calendar
        elif command -v evolution >/dev/null 2>&1; then
            launch evolution -c calendar
        elif command -v gnome-control-center >/dev/null 2>&1; then
            launch_shell 'gnome-control-center datetime || gnome-control-center'
        fi
        ;;
    datetime-settings)
        command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center datetime || gnome-control-center'
        ;;
    clocks)
        if command -v gnome-clocks >/dev/null 2>&1; then
            launch gnome-clocks
        else
            command -v gnome-control-center >/dev/null 2>&1 && launch_shell 'gnome-control-center datetime || gnome-control-center'
        fi
        ;;
    weather)
        if command -v gnome-weather >/dev/null 2>&1; then
            launch gnome-weather
        elif command -v xdg-open >/dev/null 2>&1; then
            launch xdg-open "https://www.yr.no/en"
        fi
        ;;
    clear-notifications)
        if command -v makoctl >/dev/null 2>&1; then
            makoctl dismiss --all >/dev/null 2>&1
        elif command -v dunstctl >/dev/null 2>&1; then
            dunstctl close-all >/dev/null 2>&1
        elif command -v swaync-client >/dev/null 2>&1; then
            swaync-client --close-all >/dev/null 2>&1
        fi
        ;;
esac
