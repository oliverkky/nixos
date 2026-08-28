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
  hyprMonitorHdr =
    monitor:
    let
      hdr = monitor.hdr or { };
    in
    lib.optionalString (hdr.enable or false) (
      lib.concatStringsSep "," [
        monitor.output
        (toString hdr.bitdepth)
        hdr.cm
        (toString hdr.sdrbrightness)
        (toString hdr.sdrsaturation)
        (toString hdr.supportsWideColor)
        (toString hdr.supportsHdr)
      ]
    );
  hyprMonitorHdrs = lib.concatStringsSep ";" (
    lib.filter (value: value != "") (map hyprMonitorHdr (host.monitors or [ ]))
  );
  secondaryMonitor = host.secondaryMonitor or null;
  secondaryMonitorWorkspace = host.secondaryMonitorWorkspace or null;
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
      enable = true;
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
      HYPR_MONITOR_HDRS = hyprMonitorHdrs;
      HYPR_PRIMARY_MONITOR = host.primaryMonitor;
      HYPR_PRIMARY_MONITOR_SCALE = toString (
        (lib.findFirst (monitor: monitor.output == host.primaryMonitor) { scale = 1; } (
          host.monitors or [ ]
        )).scale
      );
      HYPR_SECONDARY_MONITOR = if secondaryMonitor == null then "" else secondaryMonitor;
      HYPR_SECONDARY_MONITOR_WORKSPACE =
        if secondaryMonitorWorkspace == null then "" else toString secondaryMonitorWorkspace;
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = host.cursor.name;
      XCURSOR_SIZE = toString host.cursor.size;
    };
  };
}
