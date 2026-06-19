# My NixOS Configuration

Personal NixOS and Home Manager configuration for `laptop1`... for now.

## Rebuild

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop1
```

More in `docs/rebuild-workflow.md`.

## Workstation Install

Install NixOS with the graphical installer first. After booting the installed
system, clone this repo to `/etc/nixos`, then replace the workstation hardware
placeholder with the generated hardware file:

```sh
sudo cp /etc/nixos/hardware-configuration.nix /etc/nixos/hosts/workstation/hardware-configuration.nix
```

The `#workstation` host is intentionally not rebuildable with the placeholder
hardware file, because it does not know the workstation's root filesystem yet.

If the graphical installer generated settings you still need from
`/etc/nixos/configuration.nix`, copy those into
`hosts/workstation/configuration.nix` manually. Do not copy laptop-specific
settings from `hosts/laptop1`.

Before switching, check `hosts/workstation/constants.nix`:

- `primaryMonitor` should match the workstation connector, for example `DP-1`
  or `HDMI-A-1`.
- `stateVersion` should match the NixOS release first installed on that
  machine.

Then switch to the workstation host:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#workstation
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

My setup intentionally tracks adventurous inputs now, because I'm irresponsible:

- `nixos-unstable`
- SilentSDDM from GitHub

TODO, when this approach bites me in the ass.

1. Replace or pin SilentSDDM more conservatively.
2. Move from `nixos-unstable` to a NixOS release.

## Ownership

For managed desktop files, edit this repository rather than generated files
under `~/.config`. Home Manager will replace managed targets on activation.
