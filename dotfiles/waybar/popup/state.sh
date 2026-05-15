#!/usr/bin/env bash

set -u

json_escape() {
    local text="${1//\\/\\\\}"
    text="${text//\"/\\\"}"
    text="${text//$'\n'/\\n}"
    printf '%s' "$text"
}

bool_json() {
    if [[ "${1:-false}" == "true" ]]; then
        printf 'true'
    else
        printf 'false'
    fi
}

mode="${1:-quick-settings}"

if [[ "$mode" != "quick-settings" ]]; then
    printf '{}\n'
    exit 0
fi

volume=50
muted=false
if command -v wpctl >/dev/null 2>&1; then
    volume_out="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
    [[ "$volume_out" == *"MUTED"* ]] && muted=true
    parsed_volume="$(awk '/Volume:/ {printf "%d", $2 * 100}' <<<"$volume_out" 2>/dev/null)"
    [[ -n "${parsed_volume:-}" ]] && volume="$parsed_volume"
fi

network_label="Offline"
network_detail="Not connected"
network_kind="offline"
network_connected=false
if command -v nmcli >/dev/null 2>&1; then
    active_wifi="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" {print $2; exit}')"
    active_eth="$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null | awk -F: '$2 == "ethernet" && $3 == "connected" {print $4; exit}')"
    wifi_enabled="$(nmcli -t -f WIFI general 2>/dev/null | head -n1)"

    if [[ -n "$active_eth" ]]; then
        network_label="Wired"
        network_detail="$active_eth"
        network_kind="wired"
        network_connected=true
    elif [[ -n "$active_wifi" ]]; then
        network_label="Wi-Fi"
        network_detail="$active_wifi"
        network_kind="wifi"
        network_connected=true
    elif [[ "$wifi_enabled" == "enabled" ]]; then
        network_label="Wi-Fi"
        network_detail="Enabled"
        network_kind="wifi"
    fi
fi

bluetooth_enabled=false
bluetooth_connected=false
bluetooth_detail="Off"
bluetooth_device=""
if command -v bluetoothctl >/dev/null 2>&1; then
    bt_power="$(bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}')"
    if [[ "$bt_power" == "yes" ]]; then
        bluetooth_enabled=true
        bluetooth_detail="Enabled"
    fi

    connected_device="$(bluetoothctl devices Connected 2>/dev/null | sed -n '1s/^Device [^ ]* //p')"
    if [[ -n "$connected_device" ]]; then
        bluetooth_connected=true
        bluetooth_device="$connected_device"
        bluetooth_detail="$connected_device"
    else
        first_device="$(bluetoothctl devices 2>/dev/null | sed -n '1s/^Device [^ ]* //p')"
        if [[ -n "$first_device" ]]; then
            bluetooth_device="$first_device"
            if [[ "$bluetooth_detail" == "Enabled" ]]; then
                bluetooth_detail="$first_device"
            fi
        fi
    fi
fi

power_mode="balanced"
power_mode_label="Balanced"
if command -v powerprofilesctl >/dev/null 2>&1; then
    mode_out="$(powerprofilesctl get 2>/dev/null || true)"
    case "$mode_out" in
        performance)
            power_mode="performance"
            power_mode_label="Performance"
            ;;
        power-saver)
            power_mode="power-saver"
            power_mode_label="Power Saver"
            ;;
    esac
fi

night_light=false
dark_style=false
do_not_disturb=false
if command -v gsettings >/dev/null 2>&1; then
    [[ "$(gsettings get org.gnome.settings-daemon.plugins.color night-light-enabled 2>/dev/null || true)" == "true" ]] && night_light=true
    [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)" == *"prefer-dark"* ]] && dark_style=true
    [[ "$(gsettings get org.gnome.desktop.notifications show-banners 2>/dev/null || true)" == "false" ]] && do_not_disturb=true
fi

printf '{'
printf '"volume":%s,' "$volume"
printf '"muted":%s,' "$(bool_json "$muted")"
printf '"network":{"label":"%s","detail":"%s","kind":"%s","connected":%s},' \
    "$(json_escape "$network_label")" \
    "$(json_escape "$network_detail")" \
    "$(json_escape "$network_kind")" \
    "$(bool_json "$network_connected")"
printf '"bluetooth":{"enabled":%s,"connected":%s,"detail":"%s","device":"%s"},' \
    "$(bool_json "$bluetooth_enabled")" \
    "$(bool_json "$bluetooth_connected")" \
    "$(json_escape "$bluetooth_detail")" \
    "$(json_escape "$bluetooth_device")"
printf '"power":{"mode":"%s","label":"%s"},' \
    "$(json_escape "$power_mode")" \
    "$(json_escape "$power_mode_label")"
printf '"nightLight":%s,' "$(bool_json "$night_light")"
printf '"darkStyle":%s,' "$(bool_json "$dark_style")"
printf '"doNotDisturb":%s' "$(bool_json "$do_not_disturb")"
printf '}\n'
