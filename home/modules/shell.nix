{ config, pkgs, ... }:

{
  # ── Zsh ──────────────────────────────────────────────────────────────────────
  # Full user-level Zsh config. The system module just registers zsh as a
  # valid shell; everything interactive lives here.

  programs.zsh = {
    enable = true;
    enableCompletion = true;

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ls = "eza --icons";
      tree = "eza --tree --icons";
      update = "sudo nixos-rebuild switch --flake /etc/nixos#laptop1";
      # Convenience: edit the flake and rebuild in one go
      nixedit = "cd /etc/nixos && $EDITOR .";
    };

    # Lines added to .zshrc
    initContent = ''
      export PATH="$PATH:$HOME/.local/bin"
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
      ];
      theme = "robbyrussell";
    };
  };

  # ── Core CLI tools ───────────────────────────────────────────────────────────

  home.packages = with pkgs; [
    # Modern replacements
    eza # better ls (aliased above)
    fzf # fuzzy finder
    ripgrep # rg: better grep
    fd # better find
    bat # better cat
    jq # JSON processor
    yq-go # YAML processor
    zoxide # smarter cd

    # Archive tools
    zip
    unzip
    xz
    p7zip
    zstd

    # System inspection
    btop
    iotop
    iftop
    lsof
    strace
    ltrace
    pciutils
    usbutils
    lm_sensors
    sysstat
    ethtool

    # Networking tools
    mtr
    iperf3
    dnsutils
    nmap
    ipcalc

    # Misc
    file
    which
    gnupg
    gawk
    gnused
    gnutar
    nix-output-monitor # `nom` — prettier nix build output
    glow # markdown previewer
  ];

  # ── Starship prompt ──────────────────────────────────────────────────────────
  # Replaces oh-my-zsh's robbyrussell theme with a faster, more informative
  # prompt. Remove the oh-my-zsh theme above if you enable this.
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     add_newline = false;
  #     line_break.disabled = true;
  #     aws.disabled = true;
  #     gcloud.disabled = true;
  #   };
  # };
  programs.zsh.dotDir = config.home.homeDirectory;
}
