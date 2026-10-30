#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

make_test_tmpdir test_dir
mkdir -p "$test_dir/bin" "$test_dir/runtime"

make_stub "$test_dir/bin" find <<'EOF'
#!/usr/bin/env bash
[[ ${TEST_MODE:-} != ac ]]
EOF

make_stub "$test_dir/bin" bluetoothctl <<'EOF'
#!/usr/bin/env bash
case "$1" in
    show)
        printf 'Powered: yes\nDiscovering: no\n'
        ;;
    devices)
        count=0
        [[ ! -f $TEST_COUNT_FILE ]] || read -r count < "$TEST_COUNT_FILE"
        printf '%s\n' "$((count + 1))" > "$TEST_COUNT_FILE"
        case "$TEST_MODE" in
            connected) printf 'Device AA:BB:CC:DD:EE:FF WH-CH720N\n' ;;
            failed) printf 'Failed to connect to bus\n' >&2; exit 1 ;;
            reconnected) [[ $count -eq 0 ]] || printf 'Device AA:BB:CC:DD:EE:FF WH-CH720N\n' ;;
        esac
        ;;
    power)
        printf '%s\n' "$2" >> "$TEST_POWER_LOG"
        ;;
esac
EOF

export PATH="$test_dir/bin:$PATH"
export XDG_RUNTIME_DIR="$test_dir/runtime"
export TEST_COUNT_FILE="$test_dir/count"
export TEST_POWER_LOG="$test_dir/power.log"
script="$ROOT/dotfiles/hypr/scripts/bluetooth-auto-power-save"
idle_file="$XDG_RUNTIME_DIR/bluetooth-auto-power-save-idle-since"

reset_case() {
    rm -f "$idle_file" "$TEST_COUNT_FILE" "$TEST_POWER_LOG"
    export TEST_MODE=$1
}

reset_case connected
printf '%s\n' "$(($(date +%s) - 601))" > "$idle_file"
"$script"
assert_equal "connected headphones prevent idle state" "no" "$(test -e "$idle_file" && printf yes || printf no)"

reset_case failed
printf '%s\n' "$(($(date +%s) - 601))" > "$idle_file"
"$script"
assert_equal "failed BlueZ query cannot power off Bluetooth" "no" "$(test -e "$TEST_POWER_LOG" && printf yes || printf no)"
assert_equal "failed BlueZ query clears idle state" "no" "$(test -e "$idle_file" && printf yes || printf no)"

reset_case idle
"$script"
assert_equal "first idle reading only records state" "no" "$(test -e "$TEST_POWER_LOG" && printf yes || printf no)"
printf '%s\n' "$(($(date +%s) - 601))" > "$idle_file"
"$script"
assert_equal "sustained idle powers off Bluetooth" "off" "$(<"$TEST_POWER_LOG")"

reset_case reconnected
printf '%s\n' "$(($(date +%s) - 601))" > "$idle_file"
"$script"
assert_equal "connection on final recheck prevents shutdown" "no" "$(test -e "$TEST_POWER_LOG" && printf yes || printf no)"

reset_case ac
printf '%s\n' "$(($(date +%s) - 601))" > "$idle_file"
"$script"
assert_equal "AC power clears idle state" "no" "$(test -e "$idle_file" && printf yes || printf no)"
