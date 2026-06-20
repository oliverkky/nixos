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
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      cursorTheme = {
        name = host.cursor.name;
        package = pkgs.bibata-cursors;
        size = host.cursor.size;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk4.theme = config.gtk.theme;
      gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    };

    dconf.settings."org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
    };
  };
}
