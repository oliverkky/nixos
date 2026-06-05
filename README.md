# My NixOS Configuration

Personal NixOS and Home Manager configuration for `laptop1`... for now.

## Rebuild

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop1
```

More in `docs/rebuild-workflow.md`.

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

My setup intentionally tracks adventurous inputs now, because I'm irresponsible:

- `nixos-unstable`
- upstream Hyprland
- SilentSDDM from GitHub

TODO, when this approach bites me in the ass.

1. Switch Hyprland back to the nixpkgs package once the needed version is there.
2. Replace or pin SilentSDDM more conservatively.
3. Move from `nixos-unstable` to a NixOS release.

## Ownership

For managed desktop files, edit this repository rather than generated files
under `~/.config`. Home Manager will replace managed targets on activation.
