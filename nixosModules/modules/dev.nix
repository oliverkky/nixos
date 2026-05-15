{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Editors
    neovim
    zed-editor

    # Rust toolchain
    rustc
    rustfmt
    cargo
    rust-analyzer

    # Python — use python3.withPackages so the interpreter and libs
    # are on the same store path. Avoids the pip conflict entirely.
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

    # Codex CLI
    inputs.codex-cli-nix.packages.${pkgs.system}.default
  ];
}
