# Rebuild Workflow

Use this sequence when changing the NixOS repo.

## Fast Evaluation

```sh
nix flake check --no-build
```

Checks flake outputs and module evaluation without building the full system.

## Update Inputs

Treat `flake.lock` as the release boundary. Update inputs in a dedicated change,
not as a side effect of unrelated config work.

```sh
nix flake update
```

After updating, run the fast evaluation and build every declared host before
testing activation:

```sh
nix flake check --no-build
nix build .#nixosConfigurations.laptop1.config.system.build.toplevel --no-link
nix build .#nixosConfigurations.workstation.config.system.build.toplevel --no-link
```

## Build The System Closure

```sh
nix build .#nixosConfigurations.laptop1.config.system.build.toplevel --no-link
```

Builds the system generation without adding a `result` symlink.

## Test Activation

```sh
sudo nixos-rebuild test --flake /etc/nixos#laptop1
```

Activates the new configuration temporarily. It is not the boot default.

## Switch

```sh
sudo nixos-rebuild switch --flake /etc/nixos#laptop1
```

Activates the configuration and makes it the default boot entry.

## Clean Nix Garbage

```sh
sudo nix-collect-garbage --delete-older-than 14d
```

Removes old, unreachable Nix store paths and generations older than 14 days.
Use this after confirming the current system generation works.

```sh
sudo nix-collect-garbage -d
```

## Clean Boot Menu

```sh
sudo nixos-rebuild boot --flake /etc/nixos#laptop1
```

Regenerates the bootloader entries from the remaining system generations. This
is useful after garbage collection if old boot entries are still visible.
