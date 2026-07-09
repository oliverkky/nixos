{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.desktop.gaming = {
    enable = lib.mkEnableOption "gaming programs and runtime support";
    steamRemotePlay.openFirewall = lib.mkEnableOption "Steam Remote Play firewall ports";
    steamLocalNetworkTransfers.openFirewall = lib.mkEnableOption "Steam local network game transfer firewall ports";
    steamDedicatedServer.openFirewall = lib.mkEnableOption "Steam dedicated server firewall ports";
  };

  config = lib.mkIf config.my.nixos.desktop.gaming.enable {
    programs.steam = {
      enable = true;
      package = pkgs.steam.override {
        extraArgs = "-pipewire";
      };
      remotePlay.openFirewall = config.my.nixos.desktop.gaming.steamRemotePlay.openFirewall;
      localNetworkGameTransfers.openFirewall =
        config.my.nixos.desktop.gaming.steamLocalNetworkTransfers.openFirewall;
      dedicatedServer.openFirewall = config.my.nixos.desktop.gaming.steamDedicatedServer.openFirewall;
    };

    hardware.graphics.enable32Bit = lib.mkDefault true;
    hardware.steam-hardware.enable = lib.mkDefault true;
  };
}
