{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.drivers.g920.enable = lib.mkEnableOption "Logitech G920 racing wheel support";

  config = lib.mkIf config.my.nixos.drivers.g920.enable {
    boot.kernelModules = [ "hid-logitech-hidpp" ];

    environment.systemPackages = [
      pkgs.oversteer
      pkgs.usb-modeswitch
    ];

    hardware.usb-modeswitch.enable = true;

    services.udev.packages = [ pkgs.oversteer ];

    services.udev.extraRules = ''
      # Logitech G920 starts as 046d:c261 and must be switched to native HID++ mode.
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c261", RUN+="${pkgs.usb-modeswitch}/bin/usb_modeswitch -v 046d -p c261 -c ${pkgs.usb-modeswitch-data}/share/usb_modeswitch/046d:c261"
    '';
  };
}
