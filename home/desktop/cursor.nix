{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.cursor.enable = lib.mkEnableOption "desktop cursor settings";

  config = lib.mkIf config.my.home.desktop.cursor.enable {
    home.pointerCursor = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };

    xresources.properties = {
      "Xcursor.size" = 24;
      "Xft.dpi" = 96; # move to constants, make dependent on host
    };
  };
}
