{ lib, ... }:

{
  options.my.host = {
    primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "oliver";
      example = "alice";
      description = "Primary local user for host-owned Home Manager and desktop integration.";
    };

    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "eDP-1";
      description = "Primary monitor connector name used by Hyprland session tooling.";
    };
  };
}
