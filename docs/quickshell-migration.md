# Waybar to Quickshell Migration

This document describes the current Waybar setup and the intended Quickshell
replacement. The goal is not to clone Waybar module-for-module. The goal is to
keep the compact glassy top-bar identity while moving interactive desktop
controls into one coherent shell.

## Goals

- Replace Waybar as the primary top bar.
- Keep the same visual rhythm: workspaces left, date/time center, system state
  right.
- Move the separate Rofi control scripts into native Quickshell panels over
  time.
- Prefer shell-native controls for networking, Bluetooth, audio, battery, power
  profiles, brightness, calendar, and session actions.
- Keep the first version small enough to ship, then grow it into a real control
  center.

## Current Waybar Setup

The current top bar is defined by:

- `dotfiles/waybar/config/top.jsonc`
- `dotfiles/waybar/style/top.css`
- module snippets under `dotfiles/waybar/config/modules/`
- Home Manager service definitions in `home/modules/desktop.nix`

Waybar runs as two user services:

- `waybar-top.service` for the main bar.
- `waybar-splash.service` for the existing splash overlay.

The top bar is 32px tall, transparent at the Waybar window level, and visually
composed from rounded translucent capsules. Colors come from pywal through
`.cache/wal/colors-waybar.css`.

### Left Area

The left area contains only Hyprland workspaces:

- persistent workspaces `1` through `4`
- no visible labels
- inactive workspaces appear as short rounded pills
- the active workspace expands to a wider pill
- all workspace indicators use the same capsule/glass styling

This is one of the strongest parts of the current setup and should be preserved
almost exactly.

### Center Area

The center currently contains:

- `group/distro-group`
- `clock`
- `group/metrics`

The clock format is:

```text
HH:MM | DD Mon YYYY
```

Its tooltip contains a month calendar with week numbers and highlighted today.

The distro group is a drawer with launchers:

- NixOS/menu launcher
- terminal
- files
- Obsidian
- browser

The metrics group includes:

- disk
- memory
- CPU
- temperature

For the Quickshell replacement, the center should initially become just the
date/time capsule. Launchers and metrics can move into a macOS/GNOME-inspired
overview or quick settings panel instead of staying in the bar.

### Right Area

The right area is one long rounded system capsule with:

- tray
- power profile
- idle inhibitor
- microphone
- output volume
- output volume slider
- Bluetooth
- network
- battery
- power menu

The visual treatment is compact and icon-first. Individual modules do not have
their own backgrounds; they sit inside the shared capsule. Disconnected,
disabled, muted, warning, and critical states are expressed through muted,
warning, and critical colors.

Existing click actions currently open Rofi scripts:

- audio opens `~/.config/rofi/scripts/control-audio`
- network opens `~/.config/rofi/scripts/control-network`
- Bluetooth opens `~/.config/rofi/scripts/control-bluetooth`
- battery opens `~/.config/rofi/scripts/control-brightness`
- power opens `~/.config/rofi/scripts/control-session`

Quickshell should replace these with native popovers/panels.

## Target Quickshell Layout

The first Quickshell version should be a single top layer shell with three fixed
zones.

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ workspaces                         date/time                         system │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Top Left: Workspaces

Keep the current visual behavior:

- four persistent workspace pills
- active workspace expands
- inactive occupied workspaces remain short
- empty persistent workspaces remain visible but subdued
- clicking a pill switches workspace
- scrolling can move between workspaces if it feels natural

Implementation notes:

- Use Quickshell's Hyprland integration for workspace state.
- Keep workspace indicators textless.
- Use the current dimensions as the baseline:
  - inactive width: about 16px
  - active width: about 32px
  - height: about 2px to 4px
  - rounded ends

### Top Center: Date And Time

Keep the top-level clock simple:

```text
HH:MM | DD Mon YYYY
```

Clicking the clock should open a calendar popover.

Calendar panel plan:

- month grid with today highlighted
- previous/next month controls
- optional week numbers
- upcoming events section later, once calendar integration exists
- GNOME Calendar-style density: calm, readable, not a giant dashboard

This gives the current Waybar clock tooltip a proper home without depending on
tooltip behavior.

### Top Right: System Capsule

The right capsule should contain, in this order:

1. Power menu
2. Battery, only on laptop or when a battery exists
3. Volume
4. Wi-Fi/Ethernet
5. Bluetooth

This differs slightly from the current Waybar order, but it matches the desired
order and makes the system area read like one quick settings entry point.

Each item should be an icon button with a concise state:

- power: power icon
- battery: battery level icon, charging glyph when charging
- volume: speaker icon by volume range, muted icon when muted
- network: Wi-Fi strength, ethernet, disconnected, or disabled icon
- Bluetooth: off, on, connected

Click behavior:

- clicking any system icon opens the relevant panel
- clicking empty space or a combined chevron can open the full quick settings
  panel
- right-click can expose advanced/system-native tools later

## Visual Direction

The current style is already close to a good Quickshell target:

- transparent bar window
- top padding around 4px
- 32px nominal height
- 12px outer margin on the right/left
- translucent surfaces
- bright but soft borders
- pill-shaped controls
- compact bold Cantarell text
- Nerd Font symbols for shell/status icons

The Quickshell version should preserve this rather than moving to a large
material dashboard.

Recommended visual language:

- Use the current pywal palette as the base.
- Keep bar controls in rounded capsules.
- Use one shared right-side system capsule instead of separate cards.
- Use popovers for controls, not separate apps.
- Use macOS Control Center as inspiration for quick toggles and sliders.
- Use GNOME as inspiration for spacing, labels, calendar density, and restraint.
- Avoid oversized hero panels, ornamental gradients, and decorative backgrounds.

Popover styling:

- translucent background, stronger than the bar
- 1px border using the current foreground/border color
- 12px to 16px radius for panels
- 8px radius for repeated rows and buttons
- subtle shadow
- icon-first controls with labels only where needed

## Desired Panels

### Quick Settings

Opened from the system capsule. This should eventually replace the Rofi control
center and parts of the separate network/Bluetooth/audio scripts.

Initial sections:

- network
- Bluetooth
- volume
- brightness on laptop
- battery/power profile on laptop
- idle inhibitor
- session controls

Layout inspiration:

- macOS-style grouped toggles for Wi-Fi, Bluetooth, and power profile
- GNOME-style sliders for volume and brightness
- compact list sections for devices/networks

### Network Panel

This is the biggest reason to move beyond Waybar.

Required behavior:

- show current Wi-Fi/Ethernet state
- show active SSID and signal strength
- list visible Wi-Fi networks
- connect to known networks
- prompt for password for unknown secured networks
- disconnect current Wi-Fi
- toggle Wi-Fi on/off
- rescan networks
- expose advanced fallback action for `nmtui` if needed

Implementation options:

- First version can shell out to `nmcli` for scanning and connecting.
- Later version can use DBus/NetworkManager bindings if Quickshell exposes
  enough of what is needed or if a small helper is worth adding.

The panel should replace:

- `dotfiles/rofi/scripts/control-network`
- Waybar network click action
- `Super+N` Rofi network binding, eventually

### Bluetooth Panel

Required behavior:

- show controller powered state
- toggle Bluetooth on/off
- show paired devices
- show connected devices first
- connect/disconnect paired devices
- trigger scan mode
- show simple battery percentage where available

Implementation options:

- Prefer Quickshell BlueZ integration for live state.
- Use `bluetoothctl` only as a fallback for actions that are awkward early on.

The panel should replace:

- `dotfiles/rofi/scripts/control-bluetooth`
- Waybar Bluetooth click action
- `Super+Shift+B` Rofi Bluetooth binding, eventually

### Audio Panel

Required behavior:

- show output volume
- mute/unmute output
- show microphone mute state
- mute/unmute microphone
- output volume slider
- optionally list output devices later

Implementation notes:

- Use Quickshell PipeWire support where possible.
- Preserve the current icon language:
  - muted output
  - low/medium/high output
  - muted microphone
  - active microphone

### Battery And Power Panel

Laptop-only visible state:

- battery percentage
- charging/discharging/full
- estimated time
- power draw if available
- warning below 30%
- critical below 15%

Controls:

- power saver
- balanced
- performance
- brightness slider

This panel should eventually absorb the current brightness/power profile Rofi
script behavior while preserving the existing power profile display logic in
`dotfiles/hypr/scripts/apply-power-profile-display`.

### Power Menu

Required actions:

- lock
- logout
- suspend
- reboot
- shutdown

This should be a small confirmation panel, not a full-screen launcher. It can
borrow the clarity of GNOME's session dialogs while keeping the current compact
visual style.

## Implementation Plan

### Phase 1: Parallel Quickshell Prototype

Do not remove Waybar immediately.

Add:

- `dotfiles/quickshell/`
- a basic `shell.qml`
- component files for:
  - `Bar.qml`
  - `WorkspacePills.qml`
  - `ClockPill.qml`
  - `SystemCapsule.qml`
  - `PanelWindow.qml`
- Home Manager package entry for `pkgs.quickshell`
- optional `quickshell.service`, disabled at first or started manually

Manual test command:

```sh
quickshell -c ~/.config/quickshell
```

Acceptance criteria:

- bar appears on the configured monitor
- workspaces track Hyprland
- clock renders in the center
- system capsule renders on the right
- no overlap at common laptop and external monitor widths

### Phase 2: Replace Top Waybar

Once the prototype is visually close:

- disable `waybar-top.service`
- enable `quickshell.service`
- keep `waybar-splash.service` temporarily if still wanted
- keep Rofi scripts as fallback actions from Quickshell panels

Home Manager changes will be in `home/modules/desktop.nix`:

- remove or comment the `waybar-top` user service
- add a `quickshell` user service
- add `quickshell` to `home.packages`
- add `xdg.configFile."quickshell".source = ../../dotfiles/quickshell`

### Phase 3: Native Popovers

Replace each Rofi dependency one at a time:

1. Power menu
2. Audio panel
3. Bluetooth panel
4. Network panel
5. Calendar panel
6. Battery/brightness/power profile panel

Network and Bluetooth should keep command fallback paths until the native panels
are reliable.

### Phase 4: Remove Obsolete Pieces

After the Quickshell shell owns the interactions:

- remove Waybar top config and service
- decide whether `waybar-splash` still has a role
- remove Rofi control scripts only after their keybindings have been moved
- decide whether Eww still owns OSD or whether Quickshell should absorb it

## NixOS And Home Manager Notes

Existing system dependencies are already aligned with the target:

- NetworkManager is enabled in `nixosModules/modules/networking.nix`.
- Bluetooth is enabled in `nixosModules/modules/desktop/bluetooth.nix`.
- UPower is enabled in `nixosModules/modules/desktop/power.nix`.
- `power-profiles-daemon` is enabled for laptop hosts in
  `nixosModules/modules/laptop/power.nix`.

The initial Quickshell Home Manager service should look roughly like:

```nix
systemd.user.services.quickshell = {
  Unit = {
    Description = "Quickshell desktop shell";
    PartOf = [ "graphical-session.target" ];
    After = [ "graphical-session.target" ];
  };
  Service = {
    ExecStart = "${pkgs.quickshell}/bin/quickshell -c %h/.config/quickshell";
    Restart = "on-failure";
  };
  Install.WantedBy = [ "graphical-session.target" ];
};
```

Keep the Waybar service nearby during the transition so rollback is a single
service switch.

## Open Design Decisions

- Whether the top-right system capsule opens one combined quick settings panel
  or separate panels per icon.
- Whether launchers stay in the bar as a hidden drawer or move to an overview.
- Whether metrics stay visible, move to a panel, or are dropped.
- Whether Quickshell should eventually replace Eww OSD.
- Whether pywal colors should be read directly by Quickshell or converted into a
  generated QML/JSON theme file.

## Recommended First Build

Start with the smallest version that proves Quickshell belongs here:

- workspace pills
- date/time pill
- right system capsule
- click-to-open power menu
- click-to-open network panel shell with current state and Wi-Fi toggle

That gives immediate value over Waybar without trying to rebuild every desktop
control at once.
