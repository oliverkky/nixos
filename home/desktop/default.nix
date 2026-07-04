{ config, lib, ... }:

{
  imports = [
    ./cursor.nix
    ./dotfiles.nix
    ./gtk.nix
    ./packages.nix
    ./reaper.nix
    ./scripts.nix
    ./services.nix
    ./vcv-rack.nix
    ./xdg.nix
  ];

  options.my.home.desktop.enable = lib.mkEnableOption "desktop user bundle";

  config = lib.mkIf config.my.home.desktop.enable {
    my.home.desktop = {
      cursor.enable = lib.mkDefault true;
      dotfiles.enable = lib.mkDefault true;
      gtk.enable = lib.mkDefault true;
      packages.enable = lib.mkDefault true;
      reaper.enable = lib.mkDefault true;
      scripts.enable = lib.mkDefault true;
      services.enable = lib.mkDefault true;
      vcv-rack.enable = lib.mkDefault true;
      xdg.enable = lib.mkDefault true;
    };
  };
}
