{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.gtk.enable = lib.mkEnableOption "GTK desktop theme settings";

  config = lib.mkIf config.my.home.desktop.gtk.enable {
    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = "Bibata-Modern-Classic";
        package = pkgs.bibata-cursors;
        size = 24;
      };
    };
  };
}
