{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.development.packages.enable = lib.mkEnableOption "user development packages";

  config = lib.mkIf config.my.home.development.packages.enable {
    home.packages = with pkgs; [
      # Nix helpers
      nil # Nix LSP
      nixd # Nix LSP used by Zed's Nix extension
      qt6.qtdeclarative # QML LSP for Zed's QML extension
      nixfmt # Nix formatter
      nix-tree # visualise the dependency graph

      # Misc dev tools
      asciidoctor
      hugo
    ];
  };
}
