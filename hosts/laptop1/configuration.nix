{
  config,
  pkgs,
  inputs,
  primaryUser,
  ...
}:

let
  laptopPanelEdid = pkgs.runCommand "mne007za1-edid" { } ''
        mkdir -p $out/lib/firmware/edid
        base64 -d > $out/lib/firmware/edid/mne007za1-60hz.bin <<'EOF'
    AP///////wAObwwUAAAAAAAfAQS1HhN4Au6Vo1RMmSYPUFQAAAABAQEBAQEBAQEBAQEBAQEBtshAoLAITnAwIDYALrwQAAAYz4VAoLAITnAwIDYALrwQAAAYAAAA/gBDU09UIFQzCiAgICAgAAAA/gBNTkUwMDdaQTEtMwogAJw=
    EOF
  '';
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "drm.edid_firmware=eDP-1:edid/mne007za1-60hz.bin"
  ];
  boot.initrd.extraFiles."lib/firmware/edid/mne007za1-60hz.bin".source =
    "${laptopPanelEdid}/lib/firmware/edid/mne007za1-60hz.bin";
  hardware.firmware = [ laptopPanelEdid ];

  # ── User ────────────────────────────────────────────────────────────────────

  my.host.primaryUser = primaryUser;

  users.users.${config.my.host.primaryUser} = {
    isNormalUser = true;
    description = "Oliver Klinkovský";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
      "input"
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

  my.host.primaryMonitor = "eDP-1";

  # ── Laptop power behavior ───────────────────────────────────────────────────

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
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
      config.my.host.primaryUser
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
  system.stateVersion = "24.11";
}
