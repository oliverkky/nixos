#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
stub_dir="$test_dir/bin"
mkdir -p "$stub_dir" "$test_dir/runtime"
export COMMAND_LOG="$test_dir/hyprctl.log"
touch "$COMMAND_LOG"

make_stub "$stub_dir" hyprctl <<'EOF'
set -euo pipefail

case "$*" in
    "-j monitors all")
        printf '%s\n' '[{"name":"eDP-1","description":"Internal","availableModes":["1920x1080@60.00Hz"]},{"name":"DP-1","description":"External","availableModes":["2560x1440@75.00Hz"]}]'
        ;;
    "-j monitors")
        printf '%s\n' '[{"name":"eDP-1","description":"Internal","focused":true,"x":0,"y":0,"width":1920,"height":1080,"refreshRate":60.0,"scale":1.0}]'
        ;;
    eval\ *)
        printf '%s\n' "$*" >> "$COMMAND_LOG"
        ;;
    *)
        printf 'unexpected hyprctl arguments: %s\n' "$*" >&2
        exit 1
        ;;
esac
EOF

export PATH="$stub_dir:$PATH"
export XDG_RUNTIME_DIR="$test_dir/runtime"
displayctl="$ROOT/dotfiles/hypr/scripts/displayctl"

state=$("$displayctl" state)
assert_equal "displayctl reports the focused monitor" "eDP-1" "$(jq -r .focused <<<"$state")"
assert_equal "displayctl includes disabled connected monitors" "false" "$(jq -r '.monitors[] | select(.name == "DP-1") | .enabled' <<<"$state")"

"$displayctl" set-mode eDP-1 1920x1080@60 1.25
assert_file_contains "displayctl generates a Hyprland monitor operation" "$COMMAND_LOG" 'output = "eDP-1"'
assert_file_contains "displayctl preserves the requested scale" "$COMMAND_LOG" 'scale = 1.25'
