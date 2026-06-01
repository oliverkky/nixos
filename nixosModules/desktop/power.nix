{ config, lib, ... }:

{
  options.my.nixos.desktop.power.enable = lib.mkEnableOption "desktop power telemetry";

  config = lib.mkIf config.my.nixos.desktop.power.enable {
    # Battery telemetry service used by desktop tools and the upower CLI.
    services.upower.enable = true;
  };
}
