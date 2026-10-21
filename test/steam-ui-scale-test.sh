#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

gcc -shared -fPIC -O2 -Wall -Wextra -Werror \
    -o "$test_dir/libsteam-ui-scale.so" "$ROOT/pkgs/steam-ui-scale.c" -ldl -lm

cat >"$test_dir/mock-cef.c" <<'EOF'
#include <stdio.h>
#include <stdlib.h>

int cef_initialize(const void *a, const void *b, void *c, void *d) {
    (void)a; (void)b; (void)c; (void)d;
    return getenv("MOCK_INIT_FAIL") ? 0 : 1;
}

void cef_set_force_device_scale_factor(double scale) {
    printf("scale=%g\n", scale);
}
EOF

cat >"$test_dir/helper.c" <<'EOF'
#include <stdio.h>

extern int cef_initialize(const void *, const void *, void *, void *);

int main(void) {
    printf("result=%d\n", cef_initialize(0, 0, 0, 0));
    return 0;
}
EOF

gcc -shared -fPIC -o "$test_dir/libcef.so" "$test_dir/mock-cef.c"
gcc -o "$test_dir/steamwebhelper" "$test_dir/helper.c" \
    -L"$test_dir" -lcef -Wl,-rpath,"$test_dir"
cp "$test_dir/steamwebhelper" "$test_dir/otherhelper"

output=$(STEAM_UI_SCALE=1.5 LD_PRELOAD="$test_dir/libsteam-ui-scale.so" "$test_dir/steamwebhelper")
[[ $output == $'scale=1.5\nresult=1' ]] || fail "Steam web helper applies the requested scale"
pass "Steam web helper applies the requested scale"

output=$(STEAM_UI_SCALE=1.5 LD_PRELOAD="$test_dir/libsteam-ui-scale.so" "$test_dir/otherhelper")
[[ $output == 'result=1' ]] || fail "other processes remain unscaled"
pass "other processes remain unscaled"

output=$(STEAM_UI_SCALE=invalid LD_PRELOAD="$test_dir/libsteam-ui-scale.so" "$test_dir/steamwebhelper" 2>/dev/null)
[[ $output == 'result=1' ]] || fail "invalid scales leave the helper running"
pass "invalid scales leave the helper running"

output=$(MOCK_INIT_FAIL=1 STEAM_UI_SCALE=1.5 LD_PRELOAD="$test_dir/libsteam-ui-scale.so" "$test_dir/steamwebhelper")
[[ $output == 'result=0' ]] || fail "failed CEF initialization does not apply scaling"
pass "failed CEF initialization does not apply scaling"
