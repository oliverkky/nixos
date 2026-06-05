{ config, lib, ... }:

{
  imports = [
    ./maintenance.nix
    ./power.nix
  ];

  options.my.nixos.laptop.enable = lib.mkEnableOption "laptop system bundle";

  config = lib.mkIf config.my.nixos.laptop.enable {
    my.nixos.laptop = {
      maintenance.enable = lib.mkDefault true;
      power.enable = lib.mkDefault true;
    };
  };
}
