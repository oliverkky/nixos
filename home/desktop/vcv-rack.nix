{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  hostVcvRackLatency = host.vcvRack.pipewireLatency or null;
  pipewireLatency =
    if hostVcvRackLatency == null then
      host.reaper.pipewireLatency or "128/48000"
    else
      hostVcvRackLatency;
  vcvRack = pkgs.callPackage ../../pkgs/vcv-rack-pipewire-jack.nix { } {
    inherit pipewireLatency;
  };
in
{
  options.my.home.desktop.vcv-rack.enable = lib.mkEnableOption "VCV Rack";

  config = lib.mkIf config.my.home.desktop.vcv-rack.enable {
    home.packages = [ vcvRack ];
  };
}
