# Config Ownership

The repo is the source of truth for declared desktop configuration.

## Source Of Truth

Edit these files:

- `/etc/nixos/flake.nix`
- `/etc/nixos/hosts/*`
- `/etc/nixos/nixosModules/*`
- `/etc/nixos/home/*`
- `/etc/nixos/dotfiles/*`

Home Manager then installs those files into the locations expected by desktop
applications.

## Runtime Interface

Applications read configuration from paths under `~/.config`, for example:

- `~/.config/hypr`
- `~/.config/waybar`
- `~/.config/rofi`
- `~/.config/mako`

For managed files, treat `~/.config` as generated output. Do not edit those
files directly; the next Home Manager activation can replace them.

## Generated Config

Some files combine shared dotfiles with host-specific Nix options.

Current example:

- Waybar templates, modules, scripts, and styles live in
  `/etc/nixos/dotfiles/waybar`.
- `home/modules/desktop.nix` renders final Waybar `top.jsonc` and
  `splash.jsonc` from `dotfiles/waybar/config/top.jsonc` and
  `dotfiles/waybar/config/splash.jsonc`.
- the rendered Waybar configs set `output` from `my.host.primaryMonitor`.

This keeps monitor details declared once per host while the shared Waybar
configuration remains hardware-independent.

## App-Created State

Not everything under `~/.config` needs to be declared. App-created state can
remain unmanaged when it is local, disposable, or not worth carrying across
machines.

Examples:

- recent files
- window geometry
- caches
- account/session state
- machine-local app preferences
