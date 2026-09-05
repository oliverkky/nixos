#!/usr/bin/env bash

set -euo pipefail

source "$(dirname -- "${BASH_SOURCE[0]}")/lib/base-test.sh"

mapfile -t scripts < <(
    find \
        "$ROOT/dotfiles/desktop/scripts" \
        "$ROOT/dotfiles/hypr/scripts" \
        "$ROOT/dotfiles/rofi/scripts" \
        -maxdepth 1 -type f -print | sort
)

for script in "${scripts[@]}"; do
    [[ -x $script ]] || fail "$(realpath --relative-to="$ROOT" "$script") is executable"
    head -n 1 "$script" | grep -Eq '^#!.*(ba)?sh$' ||
        fail "$(realpath --relative-to="$ROOT" "$script") has an approved shebang"
done
pass "desktop scripts are executable and have approved shebangs"

# Rofi helpers resolve control-lib from their Nix-provided runtime directory,
# which ShellCheck cannot infer from the environment-backed path.
shellcheck -x -e SC1090,SC1091 "${scripts[@]}"
pass "desktop scripts pass shellcheck"

while IFS= read -r shell_file; do
    bash -n "$shell_file"
done < <(find "$ROOT/test" -type f -name '*.sh' -print)
pass "test scripts parse as Bash"

while IFS= read -r json_file; do
    python3 - "$json_file" <<'PY'
import json
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text()
text = re.sub(r"^\s*//.*$", "", text, flags=re.MULTILINE)
text = re.sub(r",(\s*[}\]])", r"\1", text)
json.loads(text)
PY
done < <(find "$ROOT/dotfiles" -type f -name '*.json' -print)
pass "JSON and repository-style JSONC configuration parse"

while IFS= read -r lua_file; do
    luac -p "$lua_file"
done < <(find "$ROOT/dotfiles/hypr" -type f -name '*.lua' -print)
pass "Hyprland Lua configuration parses"

while IFS= read -r backend; do
    [[ -f "$ROOT/dotfiles/hypr/scripts/$backend" ]] ||
        fail "Home Manager references existing Hyprland backend $backend"
done < <(
    sed -n 's|.*hyprScripts}/bin/\([a-z0-9-]*\).*|\1|p' \
        "$ROOT/home/desktop/scripts.nix" \
        "$ROOT/home/desktop/services.nix" | sort -u
)
pass "Home Manager Hyprland script references resolve"

desktopctl="$ROOT/dotfiles/desktop/scripts/desktopctl"
routes=$("$desktopctl" commands)
while IFS= read -r route; do
    grep -Fxq "$route" <<<"$routes" || fail "Hyprland binding uses a declared desktopctl route: $route"
done < <(sed -n 's/.*exec_cmd("desktopctl \([^"]*\)").*/\1/p' "$ROOT/dotfiles/hypr/lua/binds.lua")
pass "Hyprland desktopctl bindings use declared routes"

rg -q '"desktopctl", "display"' "$ROOT/dotfiles/quickshell/components/DisplayPopover.qml" ||
    fail "display popover uses desktopctl"
rg -q '"desktopctl", "screenshot"' "$ROOT/dotfiles/quickshell/components/ScreenshotPopover.qml" ||
    fail "screenshot popover uses desktopctl"
rg -q '^post_command = desktopctl wallpaper apply ' "$ROOT/dotfiles/waypaper/config.ini" ||
    fail "Waypaper uses desktopctl"
pass "desktop UI callers use the unified command"
