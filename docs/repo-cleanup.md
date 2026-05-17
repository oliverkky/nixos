# Repo Cleanup Notes

This file tracks cleanup work that makes the NixOS repo smaller, clearer, and easier to carry across machines.

## Completed Cleanup

### Package Consolidation

User-session tools now live in Home Manager instead of the system package list:

- `grim`
- `slurp`
- `wl-clipboard`
- `hypridle`
- `polkit_gnome`

Other package ownership decisions:

- Kitty is provided by Home Manager through `programs.kitty`; the system-level `kitty` package was removed.
- `unzip` is kept in `home/modules/shell.nix`; the system-level `unzip` package was removed.
- `btop` is kept in `home/modules/shell.nix`; the duplicate development package entry was removed.

### Single App Path Per Desktop Function

Screenshot:

- Kept `grim`, `slurp`, `wl-clipboard`, and `dotfiles/rofi/scripts/control-screenshot`.
- Removed `hyprshot`.

Wallpaper:

- Kept `awww`, `waypaper`, `dotfiles/waypaper/config.ini`, and `dotfiles/waypaper/style.css`.
- Removed `dotfiles/hypr/hyprpaper.conf`.
- Removed nested `dotfiles/hypr/waypaper` state.
- Removed stale `swww` Waypaper settings.

Bluetooth:

- Kept `services.blueman.enable`.
- Kept Rofi Bluetooth controls based on `bluetoothctl`.
- Removed `overskride`.
- Waybar Bluetooth actions now open the Rofi Bluetooth controller.

Session / power UI:

- Kept Rofi session controls using `systemctl`.
- Removed `hyprshutdown`.

Calendar:

- Kept `gnome-calendar`.
- Removed `khal`.
- Removed Khal-specific agenda logic from `dotfiles/waybar/popup/center-state.sh`.

### Dotfile Cleanup

- Removed `dotfiles/hypr.backup-20260515-155816/`.
- Removed old `dotfiles/rofi/applets/`.
- Removed old `dotfiles/rofi/launchers/type-3/launcher.sh`.
- Kept the active `dotfiles/rofi/scripts/*` control path.
- Lua remains the canonical Hyprland config path.

### Module Structure

`nixosModules/modules/desktop.nix` is now an aggregator that imports smaller responsibility-focused modules:

- `desktop/audio.nix`
- `desktop/bluetooth.nix`
- `desktop/display-manager.nix`
- `desktop/hyprland.nix`
- `desktop/packages.nix`
- `desktop/power.nix`

Host display data now uses a typed local option:

- `my.host.primaryMonitor = "eDP-1";`

Shared desktop config derives machine-specific output targeting from that option:

- Hyprland session tooling still receives `HYPR_PRIMARY_MONITOR`, but the environment variable is generated from the typed option.
- Home Manager generates Waybar `top.jsonc` and `splash.jsonc` with `output` set to the same primary monitor.
- Shared Waybar module/style/script dotfiles stay hardware-independent.

### Update / Reliability

Rebuild workflow documentation was added:

- `docs/rebuild-workflow.md`

The flake now exposes a formatter:

- `formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt`

Standard formatting command:

```sh
nix fmt
```

## Remaining Work

### Future Host Display Model

The current host option only tracks the primary monitor connector. If this repo grows to more complex monitor setups, extend `my.host` with typed display data such as:

- scale
- refresh rates
- EDID quirks
- per-host monitor layout

### Future Optional Profiles

Keep these out of the minimal desktop base:

- gaming
- music production
- Windows plugin support
- Minecraft / launchers
- low-latency audio tuning

Suggested future module names:

- `profiles/gaming.nix`
- `profiles/audio-production.nix`
- `profiles/dev-heavy.nix`

Reasoning: optional high-surface-area capabilities should not make the base desktop harder to debug.
