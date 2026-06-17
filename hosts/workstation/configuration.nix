{
  config,
  host,
  pkgs,
  ...
}:

{
  imports = [
    ./graphics.nix
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.windows.windows = {
    title = "Windows";
    efiDeviceHandle = "FS1";
    sortKey = "z_windows";
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # ── User ────────────────────────────────────────────────────────────────────

  users.users.${host.primaryUser} = {
    isNormalUser = true;
    description = "Oliver Klinkovský";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "render"
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

  # ── Data disks ──────────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    ldmtool
    ntfs3g
  ];

  systemd.services.ldmtool-create-all = {
    description = "Create Windows Dynamic Disk device-mapper volumes";
    wantedBy = [
      "mnt-bigboi.mount"
      "mnt-hdd.mount"
      "mnt-ssd.mount"
    ];
    before = [
      "mnt-bigboi.mount"
      "mnt-hdd.mount"
      "mnt-ssd.mount"
    ];
    wants = [ "systemd-udev-settle.service" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ldmtool}/bin/ldmtool create all";
      RemainAfterExit = true;
    };
  };

  systemd.tmpfiles.rules = [
    "d /mnt/bigboi 0755 root root -"
  ];

  fileSystems."/mnt/bigboi" = {
    device = "/dev/disk/by-label/BigBoi";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=BigBoi"
    ];
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-label/HDD";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=HDD"
    ];
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/SSD";
    fsType = "ntfs3";
    options = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=0022"
      "nofail"
      "x-systemd.device-timeout=5s"
      "x-gvfs-show"
      "x-gvfs-name=SSD"
    ];
  };

  my.nixos = {
    desktop = {
      enable = true;
      audio.production.enable = true;
      gaming.enable = true;
    };
    development = {
      enable = true;
      codexCli.enable = true;
    };
    drivers = {
      dualsense.enable = true;
      g920.enable = true;
    };
    networking = {
      enable = true;
      hostName = host.hostName;
    };
    shell.enable = true;
  };

  # ── Nix ─────────────────────────────────────────────────────────────────────

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (_final: prev: {
      ldmtool = prev.ldmtool.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''

          substituteInPlace src/ldmtool.c \
            --replace-fail 'ldm_new(&err)' 'ldm_new()'
        '';
      });
    })
  ];

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
