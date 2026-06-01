{ config, lib, ... }:

{
  imports = [
    ./power.nix
  ];

  options.my.nixos.laptop.enable = lib.mkEnableOption "laptop system bundle";

  config = lib.mkIf config.my.nixos.laptop.enable {
    my.nixos.laptop.power.enable = lib.mkDefault true;
  };
}
