{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.shell.packages.enable = lib.mkEnableOption "user shell packages";

  config = lib.mkIf config.my.home.shell.packages.enable {
    home.packages = with pkgs; [
      # Modern replacements
      eza # better ls (aliased in zsh.nix)
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
      nix-output-monitor # `nom`: prettier nix build output
      glow # markdown previewer
    ];
  };
}
