#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
stub_dir="$test_dir/bin"
mkdir -p "$stub_dir" "$test_dir/pictures"
export COMMAND_LOG="$test_dir/commands.log"
touch "$COMMAND_LOG"

make_stub "$stub_dir" date <<'EOF'
printf '2026-08-31-12-00-00\n'
EOF
make_stub "$stub_dir" slurp <<'EOF'
printf '10,20 800x600\n'
EOF
make_stub "$stub_dir" grim <<'EOF'
set -euo pipefail
printf 'grim\t%s\n' "$*" >> "$COMMAND_LOG"
for argument in "$@"; do
    output=$argument
done
touch "$output"
EOF
make_logging_stub "$stub_dir" wl-copy
make_logging_stub "$stub_dir" notify-send

export PATH="$stub_dir:$PATH"
export XDG_PICTURES_DIR="$test_dir/pictures"
screenshotctl="$ROOT/dotfiles/hypr/scripts/screenshotctl"

"$screenshotctl" area 0 no-pointer
image="$XDG_PICTURES_DIR/Screenshots/Screenshot_2026-08-31-12-00-00.png"
[[ -f $image ]] || fail "screenshotctl creates the screenshot"
pass "screenshotctl creates the screenshot"
assert_file_contains "screenshotctl uses the selected area" "$COMMAND_LOG" "$(printf 'grim\t-g 10,20 800x600 %s' "$image")"
assert_file_contains "screenshotctl copies the image" "$COMMAND_LOG" 'wl-copy'
assert_file_contains "screenshotctl sends a notification" "$COMMAND_LOG" "$(printf 'notify-send\tScreenshot\t%s' "$image")"
