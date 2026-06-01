# Waybar to Quickshell Migration

This document tracks the migration from a Waybar/Eww/Rofi desktop surface to a
Quickshell-owned shell. It should describe the current state first, then the
remaining direction.

The goal is still the same: keep the compact glassy top-bar identity, but move
desktop controls into one coherent Quickshell configuration instead of spreading
them across Waybar modules, Eww windows, and Rofi scripts.

## Current State

Quickshell is now the primary shell surface.

Implemented pieces live under:

- `dotfiles/quickshell/shell.qml`
- `dotfiles/quickshell/components/Bar.qml`
- `dotfiles/quickshell/components/Workspaces.qml`
- `dotfiles/quickshell/components/Clock.qml`
- `dotfiles/quickshell/components/StatusArea.qml`
- `dotfiles/quickshell/components/Osd.qml`
- `dotfiles/quickshell/components/Splash.qml`
- shared components such as `ColorScheme.qml`, `IconButton.qml`,
  `PanelAction.qml`, `PopoverSurface.qml`, and `SliderRow.qml`

Home Manager wires Quickshell through `home/desktop`:

- `xdg.configFile.quickshell.source = ../../dotfiles/quickshell`
- `home.packages` includes `pkgs.quickshell`
- `systemd.user.services.quickshell` is enabled for the graphical session
- a hidden `oliver.quickshell` desktop entry exists for the AppId/portal path
- the service seeds `%t/quickshell-osd/state.json` before startup so the OSD
  file watcher has a real path to watch

Waybar has been removed from the active Home Manager graph and from
`dotfiles`. Quickshell owns the top bar and splash surface.

Eww is no longer part of the active desktop setup. The old OSD daemon service,
package entry, and config symlink have been removed.

## Current Layout

The top bar keeps three fixed zones:

```text
┌──────────────────────────────────────────────────────────────────────────────┐
│ workspaces                         date/time                          status │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Workspaces

`Workspaces.qml` owns the left side.

Current behavior:

- at least four Hyprland workspace indicators
- the rendered range is `1..N`, where `N` is the largest of four, the active
  workspace number, and the highest occupied workspace number
- textless indicators
- active workspace expands
- occupied inactive workspaces remain visible
- empty workspaces inside the rendered range stay visible but subdued
- click switches workspace
- scroll moves within the currently rendered workspace range

The workspace sizing is intentionally local to `Workspaces.qml` so it can be
tuned quickly while the visual balance settles.

### Clock

`Clock.qml` owns the center.

Current behavior:

- top-level format: `HH:MM | DD Mon YYYY`
- click opens a calendar popover
- calendar supports month navigation
- today is highlighted

Future calendar work should stay restrained: compact month grid first, events
later only if calendar integration is reliable.

### Status Area

`StatusArea.qml` owns the right side.

Current order, left to right:

1. Bluetooth
2. Network
3. Volume
4. Battery, when a laptop battery exists
5. Power

This puts the power action on the far right while keeping network, Bluetooth,
audio, battery, and session actions in one shared status surface.

When the idle inhibitor is active, a small inhibitor indicator appears between
battery and power and opens the battery/power panel.

Current panels:

- power actions: lock, logout, suspend, reboot, shutdown
- network state, Wi-Fi toggle, rescan, visible networks, known-network connect,
  guarded password prompt for secured unknown networks, active Wi-Fi disconnect,
  and `nmtui` fallback
- Bluetooth controller toggle, scan toggle, paired devices, connect/disconnect,
  connected-device-first sorting, scan feedback, simple battery display where
  available, and `blueman-manager` fallback
- output volume slider, output mute toggle, microphone mute toggle, output
  device selection, input device selection, and `pavucontrol` fallback
- battery status, time/power detail, brightness slider, idle inhibitor toggle,
  and power profile controls

Right-click shortcuts are available on the Bluetooth, network, and audio bar
icons for the native fallback tools.

Status and clock expanded surfaces replace the visible collapsed segment instead
of appearing underneath it. The rounded surface starts from the collapsed pill's
geometry and expands outward while persistent header content remains visible.
New content is revealed by the expanding clipped surface below a subtle divider.
`PopoverSurface.qml` requests compositor blur through Quickshell's
`BackgroundEffect.blurRegion`, matched to the animated rounded surface.

The battery percentage must go through `batteryPercent()`. Quickshell's UPower
binding can expose `percentage` as a `0.0` to `1.0` ratio, so using the raw value
directly will show `1%` or `0%` on a healthy battery.

## OSD

Quickshell now owns the OSD through `Osd.qml`.

Media and brightness keys still call:

```sh
dotfiles/hypr/scripts/osdctl
```

That script performs the actual `wpctl` or `brightnessctl` action, then writes a
small JSON state file:

```text
$XDG_RUNTIME_DIR/quickshell-osd/state.json
```

`Osd.qml` watches that file and renders the overlay. This keeps the Hyprland
keybindings simple while removing the Eww dependency.

Current OSD actions:

- volume up
- volume down
- output mute
- microphone mute
- brightness up
- brightness down

Future OSD work can improve animation, placement, and media metadata, but the
ownership should stay in Quickshell.

## Splash Text

Quickshell now owns the splash text through `Splash.qml`.

It reads:

```text
~/.config/hypr/splash_messages.conf
```

The behavior mirrors the old Waybar splash script: ignore empty/comment lines,
pick one message randomly, and fall back to `Hello World!`.

The old `waybar-splash.service` should not come back unless Quickshell loses
this responsibility.

## Colors And Live Updates

`ColorScheme.qml` reads pywal colors from:

```text
$XDG_CACHE_HOME/wal/colors.json
```

It watches that file, so color changes should update without restarting
Quickshell once the running configuration points at the current files.

Important NixOS/Home Manager detail:

- `quickshell -p /etc/nixos/dotfiles/quickshell` runs directly from the working
  tree and sees edits immediately.
- `quickshell.service` runs `%h/.config/quickshell`, which Home Manager links to
  a Nix store generation.
- Changes under `/etc/nixos/dotfiles/quickshell` do not affect the service until
  the system generation is switched.

Apply normal changes with:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop1
systemctl --user restart quickshell.service
```

Use the source-tree command for quick iteration:

```sh
quickshell -p /etc/nixos/dotfiles/quickshell
```

## Hyprland Bindings

The old desktop-control Rofi bindings have been removed:

- `Super+X` control center
- `Super+N` network
- `Super+Shift+B` Bluetooth
- `Super+A` audio

`Super+W` now restarts `quickshell.service`, which is useful while iterating on
the shell.

Some Rofi scripts still exist for unrelated workflows such as clipboard and
screenshot. Those are outside the current Quickshell status-area migration and
can be handled separately.

## Waybar And Eww Status

Waybar:

- removed from the active Home Manager configuration
- no longer has a user service definition
- no longer has config material linked by Home Manager
- no longer has dotfiles in this repository

Eww:

- no longer owns OSD
- no longer has an active user service
- no longer appears in `home.packages`
- no longer has an active config symlink

Quickshell is now the only declared top bar and splash surface.

## Current Acceptance Criteria

The current Quickshell setup should satisfy:

- top bar appears through the user service
- workspaces track Hyprland state
- clock renders in the center
- calendar popover opens from the clock
- status area renders on the right with power on the far right
- network, Bluetooth, audio, battery, and power panels open
- media and brightness keys show the Quickshell OSD
- splash text appears without Waybar
- pywal colors load through `colors.json`
- no Waybar or Eww service is required for normal operation

## Remaining Work

### Status Area

- Decide whether to add a combined quick settings panel in addition to the
  individual panels.
- Decide whether a tray still belongs in the top bar or should remain omitted.

### Network

- Keep testing known-network connect behavior.
- Consider DBus/NetworkManager integration only if Quickshell's networking API
  is not enough.

### Bluetooth

- Show device battery where the BlueZ data is available.
- Keep `bluetoothctl` as a possible fallback only for actions Quickshell cannot
  do cleanly.

### Audio

- Keep PipeWire integration shell-native.
- Preserve the current icon language for muted, low, medium, high, and
  microphone states.

### Battery And Power

- Keep all percentage display routed through `batteryPercent()`.
- Preserve idle inhibitor state/control.
- Preserve power profile controls.
- Decide whether `dotfiles/hypr/scripts/apply-power-profile-display` still has
  a role or should be folded into Quickshell.
- Keep warning below 30% and critical below 15%.

### Calendar

- Keep the current compact month view.
- Add week numbers only if they do not add clutter.
- Add events later, after choosing a reliable calendar data source.

### OSD

- Tune position and dimensions across laptop and external monitors.
- Consider showing media metadata for play/pause/next/previous later.
- Keep the runtime JSON bridge unless a cleaner Quickshell IPC path is added.

### Splash

- Decide whether splash should show on every monitor or only the primary
  monitor.
- Consider refreshing the message on wallpaper/session changes.
- Keep the text lightweight and wallpaper-friendly.

### Cleanup

- Remove Rofi control scripts after every remaining useful action has a
  Quickshell or native replacement.
- Revisit older audit notes that still describe removed components as active.

## Design Direction

Keep the visual language compact and utilitarian:

- transparent shell windows
- 32px top bar target height
- small outer margins
- translucent surfaces
- soft borders
- compact bold Cantarell text
- Nerd Font status symbols
- icon-first status controls
- restrained popovers

Avoid drifting into a large dashboard. Popovers should feel like quick desktop
controls, not a separate application. The shell should stay quiet, readable, and
easy to scan.

## Expanded Surfaces

The long-term interaction model should feel like the existing bar surface
expands to reveal more information, not like a detached app window appears. The
implementation may still use Quickshell popup/layer primitives where required,
but visually the expanded state should remain attached to the control that
opened it.

Core behavior:

- clicking a bar control toggles its expanded surface
- only one expanded surface is open at a time
- clicking another control switches the expanded content without opening a
  second panel
- clicking outside, pressing Escape, or triggering the same control again closes
  the expanded surface
- the original control row remains visible inside the expanded surface header
- the header keeps the same icon order and active state as the collapsed bar
- content appears below a subtle divider
- dimensions animate from the collapsed control geometry to the expanded
  geometry
- opacity and content should fade in slightly after the size begins changing
- close animation should reverse the same path
- layout must clamp to the monitor work area and never overlap screen edges
- reduced-motion support should disable geometry animation and keep only a short
  opacity transition

The animation should be quick and quiet: roughly 140-200ms with an ease-out
curve for opening, and slightly faster for closing. Avoid bouncy, elastic, or
oversized motion. The shell should feel responsive, not theatrical.

Temporary debugging note:

- `PopoverSurface.qml` currently uses intentionally slow debug timings:
  `debugAnimationDuration: 1200` and `debugSurfaceReadyDelay: 80`.
- Before considering the expanded-surface animation settled, restore production
  timings around 140-200ms and a short first-frame handoff delay.

For example, the clock starts as:

```text
┌────────────────────────────┐
│ 12:00 │ Mon 1 January 2000 │
└────────────────────────────┘
```

When expanded, the same surface grows downward:

```text
┌────────────────────────────────────────┐
│       12:00 │ Mon 1 January 2000       │
│       ──────────────────────────       │
│                                        │
│   Calendar                             │
│    1    2    3    4    5    6    7     │
│    etc.                                │
│                                        │
│                                        │
└────────────────────────────────────────┘
```

The status area follows the same rule. Collapsed:

```text
┌─────────────────┐
│  󰂯  󰤨  󰕾  󰁹    │
└─────────────────┘
```

When Wi-Fi is selected, the surface expands leftward and downward while keeping
the status controls visible in the header:

```text
┌────────────────────────────────────────┐
│  WiFi 󰤨                 󰂯  󰤨  󰕾  󰁹    │
│  ────────────────────────────────────  │
│                                        │
│  Connected wifi name                   │
│  -------------------                   │
│  Available wifi 1                      │
│                                        │
│  Available wifi 2                      │
│                                        │
│  Available wifi 3                      │
│                                        │
│                                        │
└────────────────────────────────────────┘
```

When Bluetooth is selected, the header remains in place and only the content
mode changes:

```text
┌────────────────────────────────────────┐
│  Bluetooth 󰂯            󰂯  󰤨  󰕾  󰁹    │
│  ────────────────────────────────────  │
│                                        │
│  Connected bluetooth device 1          │
│                                        │
│  Connected bluetooth device 2          │
│  -------------------                   │
│  Available bluetooth device 1          │
│                                        │
│  Available bluetooth device 2          │
│                                        │
│  Available bluetooth device 3          │
│                                        │
│                                        │
└────────────────────────────────────────┘
```

Volume should use the same expanded-surface model and must include the output
volume slider in the first version. Later audio content can add output and input
device selection below the slider.

Power should remain compact. It can expand from the power icon, but it should
not become a large launcher or dashboard. The destructive shutdown action should
stay visually distinct.
