{ config, lib, ... }:

{
  options.my.nixos.desktop.bluetooth.enable = lib.mkEnableOption "Bluetooth desktop integration";

  config = lib.mkIf config.my.nixos.desktop.bluetooth.enable {
    hardware.bluetooth.enable = true;
    services.blueman.enable = false;
  };
}
