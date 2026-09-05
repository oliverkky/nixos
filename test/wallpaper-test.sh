#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
stub_dir="$test_dir/bin"
mkdir -p "$stub_dir" "$test_dir/state" "$test_dir/config/kitty"
export COMMAND_LOG="$test_dir/commands.log"
touch "$COMMAND_LOG"
wallpaper="$test_dir/wall paper.png"
touch "$wallpaper" "$test_dir/config/kitty/kitty.conf"

for command_name in waypaper wal hyprctl kitty awww; do
    make_logging_stub "$stub_dir" "$command_name"
done

export PATH="$stub_dir:$PATH"
export XDG_CONFIG_HOME="$test_dir/config"
export XDG_STATE_HOME="$test_dir/state"
export HYPR_SCRIPT_DIR="$ROOT/dotfiles/hypr/scripts"
export WAL_BIN=wal

"$ROOT/dotfiles/hypr/scripts/set-wallpaper" "$wallpaper"
assert_file_contains "set-wallpaper delegates to Waypaper" "$COMMAND_LOG" "$(printf 'waypaper\t--backend\tawww\t--wallpaper\t%s' "$wallpaper")"

"$ROOT/dotfiles/hypr/scripts/apply-wal" "$wallpaper"
assert_equal "apply-wal records the selected wallpaper" "$wallpaper" "$(<"$XDG_STATE_HOME/hypr/last-wallpaper")"
assert_file_contains "apply-wal generates the palette" "$COMMAND_LOG" "$(printf 'wal\t-i\t%s\t-n' "$wallpaper")"
assert_file_contains "apply-wal reloads Hyprland" "$COMMAND_LOG" $'hyprctl\treload'

"$ROOT/dotfiles/hypr/scripts/restore-wallpaper"
assert_file_contains "restore-wallpaper restores the saved image" "$COMMAND_LOG" "$(printf 'awww\timg\t--transition-type\tfade\t--transition-step\t2\t--transition-angle\t30\t--transition-duration\t1\t--transition-fps\t60\t%s' "$wallpaper")"
