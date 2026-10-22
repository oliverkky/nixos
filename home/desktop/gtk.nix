{
  config,
  host,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.gtk.enable = lib.mkEnableOption "GTK desktop theme settings";

  config = lib.mkIf config.my.home.desktop.gtk.enable {
    gtk = {
      enable = true;
      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };
      iconTheme = {
        name = "Frost-Wallust";
        package = null;
      };
      cursorTheme = {
        name = host.cursor.name;
        package = pkgs.bibata-cursors;
        size = host.cursor.size;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.theme = null;
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Frost-Wallust";
    };

    home.activation.frostIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${config.my.home.desktop.scripts.hyprPackage}/bin/update-frost-theme
    '';
  };
}
