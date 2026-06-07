{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  options.my.nixos.development = {
    enable = lib.mkEnableOption "system development tools";

    codexCli.enable = lib.mkEnableOption "Codex CLI package";
  };

  config = lib.mkIf config.my.nixos.development.enable {
    my.nixos.development.codexCli.enable = lib.mkDefault true;

    environment.systemPackages =
      with pkgs;
      [
        # Editors
        neovim
        zed-editor

        # Rust toolchain
        rustc
        rustfmt
        cargo
        rust-analyzer

        # Python: keep the interpreter and libraries on the same store path.
        (python3.withPackages (
          ps: with ps; [
            python-lsp-server
            # Add more packages here as needed, e.g.: ps.requests ps.numpy
          ]
        ))

        # C toolchain (needed for many Rust crates and Python extensions)
        gcc

        # Linting / formatting
        ruff

        # Core tools
        git
      ]
      ++ lib.optionals config.my.nixos.development.codexCli.enable [
        # Codex CLI
        inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
  };
}
