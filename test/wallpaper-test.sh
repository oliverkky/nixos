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

for command_name in waypaper wallust hyprctl kitty awww; do
    make_logging_stub "$stub_dir" "$command_name"
done

export PATH="$stub_dir:$PATH"
export XDG_CONFIG_HOME="$test_dir/config"
export XDG_STATE_HOME="$test_dir/state"
export HYPR_SCRIPT_DIR="$ROOT/dotfiles/hypr/scripts"
export WALLUST_BIN=wallust

"$ROOT/dotfiles/hypr/scripts/set-wallpaper" "$wallpaper"
assert_file_contains "set-wallpaper delegates to Waypaper" "$COMMAND_LOG" "$(printf 'waypaper\t--backend\tawww\t--wallpaper\t%s' "$wallpaper")"

"$ROOT/dotfiles/hypr/scripts/apply-wallust" "$wallpaper"
assert_equal "apply-wallust records the selected wallpaper" "$wallpaper" "$(<"$XDG_STATE_HOME/hypr/last-wallpaper")"
assert_file_contains "apply-wallust generates the palette" "$COMMAND_LOG" "$(printf 'wallust\t--quiet\t--skip-sequences\trun\t%s' "$wallpaper")"
assert_file_contains "apply-wallust reloads Hyprland" "$COMMAND_LOG" $'hyprctl\treload'

"$ROOT/dotfiles/hypr/scripts/restore-wallpaper"
assert_file_contains "restore-wallpaper restores the saved image" "$COMMAND_LOG" "$(printf 'awww\timg\t--transition-type\tfade\t--transition-step\t2\t--transition-angle\t30\t--transition-duration\t1\t--transition-fps\t60\t%s' "$wallpaper")"

export WALLUST_BIN=false
failed_wallpaper="$test_dir/failed.png"
touch "$failed_wallpaper"
set +e
"$ROOT/dotfiles/hypr/scripts/apply-wallust" "$failed_wallpaper" >/dev/null 2>&1
status=$?
set -e
assert_equal "apply-wallust reports generator failures" "1" "$status"
assert_equal "apply-wallust keeps wallpaper state in sync after generator failure" "$failed_wallpaper" "$(<"$XDG_STATE_HOME/hypr/last-wallpaper")"
