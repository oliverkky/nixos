{
  config,
  lib,
  pkgs,
  ...
}:

let
  setBatteryLongLife = pkgs.writeShellScript "set-battery-long-life" ''
    set -eu

    for battery in /sys/class/power_supply/BAT*; do
      charge_types="$battery/charge_types"

      if [ ! -w "$charge_types" ] || ! grep -qw Long_Life "$charge_types"; then
        continue
      fi

      printf Long_Life > "$charge_types" || true
    done
  '';
in
{
  options.my.nixos.laptop.power.enable = lib.mkEnableOption "laptop power management";

  config = lib.mkIf config.my.nixos.laptop.power.enable {
    # Keep power-profiles-daemon as the profile backend for desktop controls.
    services.power-profiles-daemon.enable = true;

    # Intel laptop thermal/power policy daemon. This lets the firmware and
    # kernel apply platform thermal constraints more intelligently under load.
    services.thermald.enable = true;

    # Apply powertop's tunables at boot: PCIe/runtime PM, USB autosuspend, SATA
    # link power management where available, and similar kernel power knobs.
    powerManagement.powertop.enable = true;

    # Periodically trim SSD free space.
    services.fstrim.enable = true;

    # Enable NetworkManager Wi-Fi power saving on battery-oriented machines.
    networking.networkmanager.wifi.powersave = true;

    # Enable Intel Wi-Fi firmware power saving. NetworkManager's powersave flag
    # does not necessarily flip this iwlwifi module parameter.
    boot.extraModprobeConfig = ''
      options iwlwifi power_save=1
    '';

    # Prefer the battery firmware's longevity mode when it is exposed.
    systemd.services.battery-long-life = {
      description = "Set battery charge mode to Long_Life when supported";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = setBatteryLongLife;
      };
    };

    # Tools for checking real drain and tunables after rebuild.
    environment.systemPackages = with pkgs; [
      powertop
    ];
  };
}
