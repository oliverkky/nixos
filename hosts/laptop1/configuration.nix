{
  host,
  ...
}:

{
  imports = [
    ./edid.nix
    ./hardware-configuration.nix
    ./lid.nix
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
    development.enable = true;
    laptop.enable = true;
    networking = {
      enable = true;
      allowedTCPPorts = [ 1234 8080 ];
      hostName = host.hostName;
    };
    shell.enable = true;
  };

}
