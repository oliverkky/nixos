{ config, lib, ... }:

{
  imports = [
    ./cursor.nix
    ./dotfiles.nix
    ./gtk.nix
    ./packages.nix
    ./services.nix
    ./xdg.nix
  ];

  options.my.home.desktop.enable = lib.mkEnableOption "desktop user bundle";

  config = lib.mkIf config.my.home.desktop.enable {
    my.home.desktop = {
      cursor.enable = lib.mkDefault true;
      dotfiles.enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault true;
      packages.enable = lib.mkDefault true;
      services.enable = lib.mkDefault true;
      xdg.enable = lib.mkDefault true;
    };
  };
}
