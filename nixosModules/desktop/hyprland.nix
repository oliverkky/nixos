{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  hyprMonitor =
    monitor:
    lib.concatStringsSep "," [
      monitor.output
      monitor.mode
      monitor.position
      (toString monitor.scale)
    ];
  hyprMonitors = lib.concatStringsSep ";" (map hyprMonitor (host.monitors or [ ]));
in
{
  options.my.nixos.desktop.hyprland.enable = lib.mkEnableOption "Hyprland compositor";

  config = lib.mkIf config.my.nixos.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      withUWSM = true;
      xwayland.enable = true;
    };

    # Hyprland's portal handles compositor-specific interfaces, but it does
    # not provide the file chooser used by apps such as Brave and Zed.
    xdg.portal = {
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = "gtk";
      };
    };

    environment.sessionVariables = {
      HYPR_MONITORS = hyprMonitors;
      HYPR_PRIMARY_MONITOR = host.primaryMonitor;
      HYPR_PRIMARY_MONITOR_SCALE = toString (
        (lib.findFirst (monitor: monitor.output == host.primaryMonitor) { scale = 1; } (
          host.monitors or [ ]
        )).scale
      );
      HYPR_SECONDARY_MONITOR = host.secondaryMonitor or "";
      HYPR_SECONDARY_MONITOR_WORKSPACE = toString (host.secondaryMonitorWorkspace or "");
      XCURSOR_THEME = host.cursor.name;
      XCURSOR_SIZE = toString host.cursor.size;
    };
  };
}
