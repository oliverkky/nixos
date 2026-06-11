{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.drivers.g920.enable = lib.mkEnableOption "Logitech G920 racing wheel support";

  config = lib.mkIf config.my.nixos.drivers.g920.enable {
    boot.kernelModules = [
      "hid-logitech-hidpp"
    ];

    environment.systemPackages = [
      pkgs.usb-modeswitch
    ];

    hardware.usb-modeswitch.enable = true;
  };
}
