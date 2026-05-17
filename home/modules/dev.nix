{ config, pkgs, ... }:

{
  # ── Git ──────────────────────────────────────────────────────────────────────

  programs.git = {
    enable = true;
    settings.user = {
      name = "OliverKKY";
      email = "oklink@seznam.cz";
    };
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.editor = "nvim";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  # ── Terminal emulators ───────────────────────────────────────────────────────

  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
    settings = {
      scrollback_lines = 10000;
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      background_opacity = "0.88";
      dynamic_background_opacity = true;
    };
  };

  # ── Dev packages (user-level) ─────────────────────────────────────────────────
  # Anything not needed system-wide and not better served by a devShell.

  home.packages = with pkgs; [
    # Nix helpers
    nil # Nix LSP
    nixfmt # Nix formatter
    nix-tree # visualise the dependency graph

    # Misc dev tools
    hugo
  ];
}
