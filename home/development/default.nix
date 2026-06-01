{ config, lib, ... }:

{
  imports = [
    ./git.nix
    ./packages.nix
    ./terminal.nix
  ];

  options.my.home.development.enable = lib.mkEnableOption "user development bundle";

  config = lib.mkIf config.my.home.development.enable {
    my.home.development = {
      git.enable = lib.mkDefault true;
      packages.enable = lib.mkDefault true;
      terminal.enable = lib.mkDefault true;
    };
  };
}
