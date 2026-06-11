{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.drivers.dualsense.enable = lib.mkEnableOption "Sony DualSense controller support";

  config = lib.mkIf config.my.nixos.drivers.dualsense.enable {
    boot.kernelModules = [
      "hid_playstation"
      "uinput"
    ];

    hardware.steam-hardware.enable = true;

    environment.systemPackages = [
      pkgs.dualsensectl
    ];

    services.udev.extraRules = ''
      # PS5 DualSense controller over USB hidraw
      KERNEL=="hidraw*", ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0660", TAG+="uaccess"

      # PS5 DualSense controller over Bluetooth hidraw
      KERNEL=="hidraw*", KERNELS=="*054C:0CE6*", MODE="0660", TAG+="uaccess"
    '';
  };
}
