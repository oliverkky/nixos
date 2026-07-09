{
  config,
  host,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.cursor.enable = lib.mkEnableOption "desktop cursor settings";

  config = lib.mkIf config.my.home.desktop.cursor.enable {
    home.pointerCursor = {
      name = host.cursor.name;
      package = pkgs.bibata-cursors;
      size = host.cursor.size;
      gtk.enable = lib.mkDefault false;
    };

    xresources.properties = {
      "Xcursor.size" = host.cursor.size;
      "Xft.dpi" = host.cursor.dpi;
    };
  };
}
