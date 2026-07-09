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
      packages = {
        networkDiscovery.enable = true;
        printing.enable = true;
      };
    };
    development.enable = true;
    laptop.enable = true;
    networking = {
      enable = true;
      hostName = host.hostName;
    };
    shell.enable = true;
  };

}
