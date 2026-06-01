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

    environment.sessionVariables = {
      HYPR_PRIMARY_MONITOR = host.primaryMonitor;
      XCURSOR_THEME = "Bibata-Modern-Classic";
      XCURSOR_SIZE = "24";
    };
  };
}
