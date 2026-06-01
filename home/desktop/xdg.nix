{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.xdg.enable = lib.mkEnableOption "desktop XDG settings";

  config = lib.mkIf config.my.home.desktop.xdg.enable {
    # Keeps your home directory clean.
    xdg = {
      enable = true;
      userDirs = {
        enable = true;
        createDirectories = true;
      };
    };
    xdg.userDirs.setSessionVariables = false;

    xdg.desktopEntries."oliver.quickshell" = {
      name = "Oliver Quickshell";
      genericName = "Desktop Shell";
      comment = "Quickshell desktop shell for the Hyprland session";
      exec = "${pkgs.quickshell}/bin/quickshell -p ${config.home.homeDirectory}/.config/quickshell";
      icon = "org.quickshell";
      terminal = false;
      type = "Application";
      categories = [ "System" ];
      settings = {
        NoDisplay = "true";
        StartupNotify = "false";
      };
    };
  };
}
