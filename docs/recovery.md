# Recovery

This repository is only useful in a bad boot if the machine can reach a shell
and enough context exists to rebuild or roll back.

## Boot Rollback

At the systemd-boot menu, select an older NixOS generation. Keep at least a few
known-good generations by leaving `boot.loader.systemd-boot.configurationLimit`
above one.

## From A Working Generation

Inspect the current and previous generations:

```sh
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

Switch back to a previous generation:

```sh
sudo /nix/var/nix/profiles/system-<number>-link/bin/switch-to-configuration switch
```

## From Installer Media

1. Boot NixOS installer media.
2. Mount the installed root filesystem at `/mnt`.
3. Mount the EFI partition at `/mnt/boot`.
4. If the system is encrypted, unlock LUKS before mounting root.
5. Enter the installed system:

```sh
sudo nixos-enter --root /mnt
```

6. Rebuild from the checked-out repository:

```sh
nixos-rebuild boot --flake /etc/nixos#laptop1
```

7. Reboot and select the repaired generation.

## Firmware And Disk Health

Firmware update support is enabled through `fwupd`:

```sh
fwupdmgr refresh
fwupdmgr get-updates
fwupdmgr update
```

Disk health monitoring is enabled through `smartd`. Manual checks:

```sh
sudo smartctl -a /dev/nvme0
sudo nvme smart-log /dev/nvme0
```
