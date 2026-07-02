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
- `~/.config/quickshell`
- `~/.config/rofi`

For managed files, treat `~/.config` as generated output. Do not edit those
files directly; the next Home Manager activation can replace them.

## Host-Specific Config

Host facts live in `hosts/<name>/constants.nix` and are passed into both NixOS
and Home Manager as `host`. Shared modules should read those facts through the
module argument instead of importing a host file directly.

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
