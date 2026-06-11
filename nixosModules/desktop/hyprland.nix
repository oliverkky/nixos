{
  config,
  host,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandVersion = pkgs.lib.removeSuffix "\n" (builtins.readFile "${inputs.hyprland}/VERSION");
  hyprlandPackage = hyprlandPackages.hyprland.overrideAttrs {
    src = inputs.hyprland;
    env = {
      GIT_COMMITS = 0;
      GIT_COMMIT_DATE = inputs.hyprland.lastModifiedDate or "";
      GIT_COMMIT_HASH = inputs.hyprland.rev or "";
      GIT_DIRTY = "clean";
      GIT_TAG = "v${hyprlandVersion}";
    };
  };
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
      package = hyprlandPackage;
      portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
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
      HYPR_SECONDARY_MONITOR = host.secondaryMonitor or "";
      HYPR_SECONDARY_MONITOR_WORKSPACE = toString (host.secondaryMonitorWorkspace or "");
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "24";
    };
  };
}
