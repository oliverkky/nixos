{
  config,
  host,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── User ────────────────────────────────────────────────────────────────────

  users.users.${host.primaryUser} = {
    isNormalUser = true;
    description = "Oliver Klinkovský";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };

  # ── Locale & Time ───────────────────────────────────────────────────────────

  time.timeZone = "Europe/Prague";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  console.keyMap = "cz-lat2";

  my.nixos = {
    desktop.enable = true;
    development.enable = true;
    networking = {
      enable = true;
      hostName = host.hostName;
    };
    shell.enable = true;
  };

  # ── Nix ─────────────────────────────────────────────────────────────────────

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Avoid redundant downloads when multiple users build
    trusted-users = [
      "root"
    ];
  };

  # Deduplicate store paths automatically
  nix.optimise.automatic = true;

  # Garbage-collect generations older than 14 days weekly
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ── State version ───────────────────────────────────────────────────────────
  # Set this to the NixOS release you FIRST installed on this machine.
  # Do NOT update it when upgrading NixOS. See `man configuration.nix`.
  system.stateVersion = host.stateVersion;
}
