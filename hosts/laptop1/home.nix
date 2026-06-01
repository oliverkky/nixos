{ config, host, ... }:

{
  imports = [
    ../../home
  ];

  home.username = host.primaryUser;
  home.homeDirectory = "/home/${config.home.username}";
  home.stateVersion = host.stateVersion;

  my.home = {
    desktop.enable = true;
    development.enable = true;
    shell.enable = true;
  };
}
