{ ... }:

{
  imports = [
    ./modules/desktop.nix
    ./modules/dev.nix
    ./modules/host-options.nix
    ./modules/networking.nix
    ./modules/shell.nix
  ];
}
