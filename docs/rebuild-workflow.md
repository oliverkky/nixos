# Rebuild Workflow

Use this sequence when changing the NixOS repo.

## Fast Evaluation

```sh
nix flake check --no-build
```

Checks flake outputs and module evaluation without building the full system.

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
