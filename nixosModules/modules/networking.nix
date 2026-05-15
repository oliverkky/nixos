{ config, pkgs, ... }:

{
  networking = {
    hostName = "laptop1";

    # NetworkManager owns all interface management.
    # Do NOT also set networking.interfaces or networking.wireless.interfaces —
    # those belong to the wpa_supplicant stack, which NM replaces.
    networkmanager.enable = true;
  };

  # Optional: firewall (enabled by default on NixOS, explicitly stated here
  # so future you knows it's intentional and where to add exceptions).
  networking.firewall = {
    enable = true;
    # allowedTCPPorts = [ 22 80 443 ];
  };
}
