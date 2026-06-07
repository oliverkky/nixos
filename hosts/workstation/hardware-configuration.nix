# Placeholder for the workstation's generated hardware configuration.
# After installing NixOS with the graphical installer, replace this file with:
#   /etc/nixos/hardware-configuration.nix
{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  warnings = [
    "Replace hosts/workstation/hardware-configuration.nix with the workstation-generated hardware-configuration.nix before switching to this host."
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
}
