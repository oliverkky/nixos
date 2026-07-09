{ host, ... }:

{
  imports = [
    ./boot.nix
    ./graphics.nix
    ./hardware-configuration.nix
    ./storage.nix
  ];

  my.nixos = {
    desktop = {
      enable = true;
      audio.production.enable = true;
      gaming.enable = true;
      packages = {
        networkDiscovery.enable = true;
        printing.enable = true;
      };
    };
    development = {
      enable = true;
      codexCli.enable = true;
    };
    drivers = {
      dualsense.enable = true;
      g920.enable = true;
    };
    networking = {
      enable = true;
      hostName = host.hostName;
    };
    shell.enable = true;
  };

}
