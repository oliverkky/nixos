{
  host,
  pkgs,
  ...
}:

let
  primaryUserUid = toString host.primaryUid;
  primaryUserGid = toString host.primaryGid;
  ntfsMountOptions = name: [
    "rw"
    "uid=${primaryUserUid}"
    "gid=${primaryUserGid}"
    "umask=0022"
    "nofail"
    "x-systemd.device-timeout=5s"
    "x-gvfs-show"
    "x-gvfs-name=${name}"
  ];
in
{
  imports = [
    ./graphics.nix
    ./hardware-configuration.nix
  ];

  # ── Boot ────────────────────────────────────────────────────────────────────

  boot.loader.systemd-boot.edk2-uefi-shell.enable = true;
  boot.loader.systemd-boot.windows.windows = {
    title = "Windows";
    # Windows lives on a separate ESP (/dev/nvme1n1p1, UUID 32BE-31C8).
    # If this entry drops to the UEFI shell, select "EDK2 UEFI Shell",
    # run `map -c`, and replace this with the handle whose EFI directory
    # contains Microsoft/Boot/Bootmgfw.efi.
    efiDeviceHandle = "HD2b";
    sortKey = "z_windows";
  };

  users.users.${host.primaryUser}.extraGroups = [ "render" ];

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
    options = ntfsMountOptions "BigBoi";
  };

  fileSystems."/mnt/hdd" = {
    device = "/dev/disk/by-label/HDD";
    fsType = "ntfs3";
    options = ntfsMountOptions "HDD";
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-label/SSD";
    fsType = "ntfs3";
    options = ntfsMountOptions "SSD";
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

}
