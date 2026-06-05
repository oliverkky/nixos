# Disk Encryption Plan

The current `laptop1` hardware profile mounts plain ext4 filesystems by UUID and
does not declare `boot.initrd.luks.devices`. Full-disk encryption cannot be
safely added as a normal rebuild; it requires reinstalling or migrating the
partition layout from rescue media.

## Target Layout

- EFI system partition at `/boot`, unencrypted.
- LUKS2 container for the main system.
- Root filesystem inside the LUKS container.
- Swap inside the encrypted container, or no persistent swap if hibernation is
  not needed.

## Reinstall Path

1. Boot NixOS installer media.
2. Back up and verify all important data first.
3. Create a small EFI partition and one LUKS2 partition for the system.
4. Open the LUKS container and create the root filesystem inside it.
5. Generate hardware config.
6. Confirm the generated config contains `boot.initrd.luks.devices`.
7. Restore `/etc/nixos`, update UUIDs, and rebuild.
8. Confirm the machine prompts for the LUKS passphrase before boot.

## NixOS Shape

The final host hardware configuration should contain a device entry like:

```nix
boot.initrd.luks.devices."cryptroot" = {
  device = "/dev/disk/by-uuid/<luks-partition-uuid>";
};
```

Root should then mount the decrypted mapper path or an inner filesystem UUID.
