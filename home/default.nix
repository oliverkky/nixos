{
  config,
  osConfig,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./modules/shell.nix
    ./modules/dev.nix
    ./modules/desktop.nix
  ];

  home.username = osConfig.my.host.primaryUser;
  home.homeDirectory = "/home/${config.home.username}";

  # Match system.stateVersion in hosts/laptop1/configuration.nix.
  # Same rule: set once at install time, never bump it.
  home.stateVersion = "24.11";
}
