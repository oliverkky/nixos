{ ... }:

{
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;

  boot.loader.systemd-boot.windows.windows = {
    title = "Windows";
    # Windows lives on a separate ESP (/dev/nvme1n1p1, UUID 32BE-31C8).
    # If this entry drops to the UEFI shell, select "EDK2 UEFI Shell",
    # run `map -c`, and replace this with the handle whose EFI directory
    # contains Microsoft/Boot/Bootmgfw.efi.
    efiDeviceHandle = "HD2b";
    sortKey = "z_windows";
  };
}
