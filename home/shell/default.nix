{ config, lib, ... }:

{
  imports = [
    ./packages.nix
    ./zsh.nix
  ];

  options.my.home.shell.enable = lib.mkEnableOption "user shell bundle";

  config = lib.mkIf config.my.home.shell.enable {
    my.home.shell = {
      packages.enable = lib.mkDefault true;
      zsh.enable = lib.mkDefault true;
    };
  };
}
