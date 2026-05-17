{ lib, ... }:

{
  options.my.host = {
    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "eDP-1";
      description = "Primary monitor connector name used by Hyprland session tooling.";
    };
  };
}
