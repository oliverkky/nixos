{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  batteryChargeType = host.battery.chargeType or null;
  setBatteryChargeType =
    chargeType:
    pkgs.writeShellScript "set-battery-charge-type" ''
      set -eu

      charge_type=${lib.escapeShellArg chargeType}

      for battery in /sys/class/power_supply/BAT*; do
        charge_types="$battery/charge_types"

        if [ ! -w "$charge_types" ] || ! grep -qw "$charge_type" "$charge_types"; then
          continue
        fi

        printf '%s' "$charge_type" > "$charge_types" || true
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

    # Select a firmware charge mode when the host declares one. Leave this
    # unset for hosts where firmware charge policy should be managed manually.
    systemd.services.battery-charge-type = lib.mkIf (batteryChargeType != null) {
      description = "Set battery charge mode when supported";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = setBatteryChargeType batteryChargeType;
      };
    };

    # Tools for checking real drain and tunables after rebuild.
    environment.systemPackages = with pkgs; [
      powertop
    ];
  };
}
