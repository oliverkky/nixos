{ config, lib, ... }:

{
  options.my.nixos.networking = {
    enable = lib.mkEnableOption "NetworkManager networking";

    hostName = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "laptop1";
      description = "Host name to apply when the networking module is enabled.";
    };

    allowedUDPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Host-specific UDP firewall exceptions.";
    };

    allowedTCPPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ ];
      description = "Host-specific TCP firewall exceptions.";
    };
  };

  config = lib.mkIf config.my.nixos.networking.enable {
    networking = {
      hostName = config.my.nixos.networking.hostName;

      # NetworkManager owns all interface management.
      # Do NOT also set networking.interfaces or networking.wireless.interfaces.
      networkmanager.enable = true;

      # Firewall is enabled by default on NixOS; keep it explicit here so
      # future exceptions have a clear home.
      firewall = {
        enable = true;
        allowedTCPPorts = config.my.nixos.networking.allowedTCPPorts;
        allowedUDPPorts = config.my.nixos.networking.allowedUDPPorts;
      };
    };
  };
}
