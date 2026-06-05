{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.laptop.maintenance.enable = lib.mkEnableOption "laptop maintenance services";

  config = lib.mkIf config.my.nixos.laptop.maintenance.enable {
    # Firmware updates via LVFS/fwupd. Updates are still explicitly applied with
    # fwupdmgr, but the daemon and refresh timer are available.
    services.fwupd.enable = true;

    # Monitor SMART/NVMe health and write warnings to logged-in users and the
    # journal. This intentionally avoids mail until an MTA exists.
    services.smartd = {
      enable = true;
      autodetect = true;
      notifications.mail.enable = false;
      notifications.wall.enable = true;
      defaults.autodetected = "-a -o on -s (S/../.././02|L/../../7/04)";
    };

    # Prefer compressed RAM before touching disk swap. Keep physical swap as the
    # lower-priority fallback configured by the hardware profile.
    zramSwap = {
      enable = true;
      memoryPercent = 50;
      priority = 100;
      algorithm = "zstd";
    };

    environment.systemPackages = with pkgs; [
      fwupd
      smartmontools
      nvme-cli
    ];
  };
}
