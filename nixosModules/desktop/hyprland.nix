{
  config,
  host,
  inputs,
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
  hyprglass = pkgs.callPackage ../../pkgs/hyprglass.nix {
    src = inputs.hyprglass;
  };
  hyprglassInit = pkgs.writeShellScript "hyprglass-init" ''
    set -eu
    ${pkgs.hyprland}/bin/hyprctl plugin load ${hyprglass}/lib/libhyprglass.so
    ${pkgs.hyprland}/bin/hyprctl --batch "keyword plugin:hyprglass:default_theme dark; keyword plugin:hyprglass:default_preset subtle; keyword plugin:hyprglass:manage_window_blur 1; keyword plugin:hyprglass:layers:enabled 1; keyword plugin:hyprglass:layers:namespaces oliver.quickshell,oliver.quickshell.notifications,oliver.quickshell.display-anchor,oliver.quickshell.screenshot,oliver.quickshell.clipboard; keyword plugin:hyprglass:layers:preset subtle; keyword plugin:hyprglass:layers:namespace_mask_thresholds oliver.quickshell=0.03,oliver.quickshell.notifications=0.03,oliver.quickshell.display-anchor=0.03,oliver.quickshell.screenshot=0.03,oliver.quickshell.clipboard=0.03"
  '';
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
      HYPR_COLOR_MANAGEMENT = lib.boolToString host.hyprland.colorManagement.enable;
      HYPR_PRIMARY_MONITOR = host.primaryMonitor;
      HYPR_PRIMARY_MONITOR_SCALE = toString (
        (lib.findFirst (monitor: monitor.output == host.primaryMonitor) { scale = 1; } (
          host.monitors or [ ]
        )).scale
      );
      HYPR_SECONDARY_MONITOR = if secondaryMonitor == null then "" else secondaryMonitor;
      HYPR_SECONDARY_MONITOR_WORKSPACE =
        if secondaryMonitorWorkspace == null then "" else toString secondaryMonitorWorkspace;
      HYPRGLASS_INIT = "${hyprglassInit}";
      HYPRCTL_PATH = "${pkgs.hyprland}/bin/hyprctl";
      NIXOS_OZONE_WL = "1";
      XCURSOR_THEME = host.cursor.name;
      XCURSOR_SIZE = toString host.cursor.size;
    };

    environment.systemPackages = [ hyprglass ];
  };
}
