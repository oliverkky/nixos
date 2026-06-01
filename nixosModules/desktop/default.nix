{ config, lib, ... }:

{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./display-manager.nix
    ./hyprland.nix
    ./packages.nix
    ./power.nix
  ];

  options.my.nixos.desktop.enable = lib.mkEnableOption "desktop system bundle";

  config = lib.mkIf config.my.nixos.desktop.enable {
    my.nixos.desktop = {
      audio.enable = lib.mkDefault true;
      bluetooth.enable = lib.mkDefault true;
      displayManager.enable = lib.mkDefault true;
      hyprland.enable = lib.mkDefault true;
      packages.enable = lib.mkDefault true;
      power.enable = lib.mkDefault true;
    };
  };
}
