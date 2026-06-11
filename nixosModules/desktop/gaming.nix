{
  config,
  lib,
  ...
}:

{
  options.my.nixos.desktop.gaming.enable = lib.mkEnableOption "gaming programs and runtime support";

  config = lib.mkIf config.my.nixos.desktop.gaming.enable {
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };

    hardware.graphics.enable32Bit = lib.mkDefault true;
    hardware.steam-hardware.enable = lib.mkDefault true;
  };
}
