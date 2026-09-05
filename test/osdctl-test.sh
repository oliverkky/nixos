#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
stub_dir="$test_dir/bin"
mkdir -p "$stub_dir" "$test_dir/runtime"
export COMMAND_LOG="$test_dir/commands.log"
touch "$COMMAND_LOG"

make_stub "$stub_dir" wpctl <<'EOF'
set -euo pipefail

printf 'wpctl\t%s\n' "$*" >> "$COMMAND_LOG"
if [[ ${1:-} == "get-volume" ]]; then
    printf 'Volume: 0.58\n'
fi
EOF

make_stub "$stub_dir" brightnessctl <<'EOF'
set -euo pipefail

printf 'brightnessctl\t%s\n' "$*" >> "$COMMAND_LOG"
if [[ ${1:-} == "-m" ]]; then
    printf 'backlight,intel_backlight,4800,48%%\n'
fi
EOF

export PATH="$stub_dir:$PATH"
export XDG_RUNTIME_DIR="$test_dir/runtime"
osdctl="$ROOT/dotfiles/hypr/scripts/osdctl"

"$osdctl" volume-up
state_file="$XDG_RUNTIME_DIR/quickshell-osd/state.json"
assert_file_contains "osdctl changes sink volume" "$COMMAND_LOG" 'set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+'
assert_equal "osdctl writes the current volume" "58" "$(jq -r .value "$state_file")"
assert_equal "osdctl makes the OSD visible" "true" "$(jq -r .visible "$state_file")"

hide_pid=$(<"$XDG_RUNTIME_DIR/quickshell-osd/hide.pid")
kill "$hide_pid" 2>/dev/null || true
wait "$hide_pid" 2>/dev/null || true

"$osdctl" brightness-set 73
assert_file_contains "osdctl sets an explicit brightness" "$COMMAND_LOG" $'brightnessctl\t-n2 set 73%'
hide_pid=$(<"$XDG_RUNTIME_DIR/quickshell-osd/hide.pid")
kill "$hide_pid" 2>/dev/null || true
wait "$hide_pid" 2>/dev/null || true
