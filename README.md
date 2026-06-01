# Oliver's NixOS Configuration

Personal NixOS and Home Manager configuration for `laptop1`.

## Rebuild

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop1
```

## Format And Check

```sh
nix fmt
nix flake check --no-build
```

## Layout

- `flake.nix` wires inputs, the formatter, the NixOS host, and Home Manager.
- `hosts/laptop1` contains machine-specific facts and hardware configuration.
- `nixosModules` contains system modules under the `my.nixos.*` option tree.
- `home` contains Home Manager modules under the `my.home.*` option tree.
- `dotfiles` contains application configs linked into `~/.config`.

## Update Posture

This setup intentionally tracks adventurous inputs:

- `nixos-unstable`
- `linuxPackages_latest`
- upstream Hyprland
- SilentSDDM from GitHub
- Brave Origin from a nixpkgs PR branch

That keeps the desktop current, but it also means updates can fail or cause
runtime regressions. When that tradeoff stops being worth it, the first
stabilization pass should pin or replace those inputs in roughly this order:

1. Use the default nixpkgs kernel instead of `linuxPackages_latest`.
2. Replace the Brave Origin PR input with a normal nixpkgs package or a stable
   external source.
3. Switch Hyprland back to the nixpkgs package once the needed version is there.
4. Replace or pin SilentSDDM more conservatively.
5. Move from `nixos-unstable` to a NixOS release branch if system updates are
   still too noisy.

## Ownership

For managed desktop files, edit this repository rather than generated files
under `~/.config`. Home Manager will replace managed targets on activation.
