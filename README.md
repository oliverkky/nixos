# My NixOS Configuration

Personal NixOS and Home Manager configuration for my machines. Maybe later for every machine.

## Philosophy

If I am to spend most of my life on a computer, I shall strive to make the experience as good as possible.

Of course, I'm shooting for a gorgeous, fast, responsive, stable, intuitive system.
The problem? In which order do I prioritize these traits?

## Layout

- `flake.nix` wires inputs, the formatter, the NixOS hosts, and Home Manager.
- `hosts/*` contains machine-specific facts and hardware configuration.
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
