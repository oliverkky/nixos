#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
stub_dir="$test_dir/bin"
mkdir -p "$stub_dir"
export COMMAND_LOG="$test_dir/commands.log"
touch "$COMMAND_LOG"

for command_name in \
    apply-power-profile-display apply-wal bluetooth-connect-a2dp \
    control-audio control-bluetooth control-brightness control-center \
    control-clipboard control-network control-screenshot control-session \
    display-info displayctl launcher osdctl restore-wallpaper screenshotctl \
    set-power-profile-display set-wallpaper; do
    make_logging_stub "$stub_dir" "$command_name"
done

export PATH="$stub_dir:$PATH"
desktopctl="$ROOT/dotfiles/desktop/scripts/desktopctl"

"$desktopctl" audio volume-up
"$desktopctl" brightness set 42
"$desktopctl" display layout extend eDP-1
"$desktopctl" power profile set balanced
"$desktopctl" screenshot window 3 no-pointer
"$desktopctl" wallpaper set "/tmp/wall paper.png"

expected=$'osdctl\tvolume-up\nosdctl\tbrightness-set\t42\ndisplayctl\tlayout\textend\teDP-1\nset-power-profile-display\tbalanced\nscreenshotctl\twindow\t3\tno-pointer\nset-wallpaper\t/tmp/wall paper.png'
assert_equal "desktopctl maps public routes and preserves arguments" "$expected" "$(<"$COMMAND_LOG")"

set +e
error_output=$("$desktopctl" brightness set 2>&1)
status=$?
set -e
assert_equal "desktopctl uses status 2 for invalid usage" "2" "$status"
assert_contains "desktopctl explains a missing argument" "$error_output" "brightness percentage is required"

routes=$("$desktopctl" commands)
assert_contains "desktopctl publishes its routes" "$routes" "power profile set"
