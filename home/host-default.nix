{ config, host, ... }:

{
  imports = [
    ./default.nix
  ];

  home.username = host.primaryUser;
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = host.stateVersion;

  my.home = {
    desktop = {
      enable = host.home.desktop.enable;
      packages.audioProduction.enable = host.home.audioProduction.enable;
      reaper.enable = host.home.audioProduction.enable;
      vcv-rack.enable = host.home.audioProduction.enable;
    };
    development.enable = host.home.development.enable;
    shell.enable = host.home.shell.enable;
  };
}
