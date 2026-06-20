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

This repo tracks current inputs for hardware and desktop support:

- `nixos-unstable`
- SilentSDDM from GitHub

That is only acceptable while the lock file is treated as the release boundary.
Do not update inputs opportunistically during unrelated changes. Input updates
should be their own change and must follow `docs/rebuild-workflow.md`:

1. Update the lock file explicitly.
2. Run flake evaluation and system builds for every declared host.
3. Test activation on the target host before switching.

Revisit this posture when either SilentSDDM breaks evaluation/builds or a NixOS
release has the desktop and hardware support this config needs.

## Ownership

For managed desktop files, edit this repository rather than generated files
under `~/.config`. Home Manager will replace managed targets on activation.
