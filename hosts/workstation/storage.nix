{ host, pkgs, ... }:

let
  ntfsMountOptions =
    name:
    let
      primaryUserUid = toString host.primaryUid;
      primaryUserGid = toString host.primaryGid;
    in
    [
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
}
