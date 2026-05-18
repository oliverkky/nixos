{ pkgs, ... }:

{
  # Keep power-profiles-daemon as the profile backend for Waybar and rofi.
  services.power-profiles-daemon.enable = true;

  # Battery telemetry service used by desktop tools and the upower CLI.
  services.upower.enable = true;

  # Intel laptop thermal/power policy daemon. This lets the firmware and kernel
  # apply platform thermal constraints more intelligently under load.
  services.thermald.enable = true;

  # Apply powertop's tunables at boot: PCIe/runtime PM, USB autosuspend, SATA
  # link power management where available, and similar kernel power knobs.
  powerManagement.powertop.enable = true;

  # Tools for checking real drain and tunables after rebuild.
  environment.systemPackages = with pkgs; [
    powertop
    upower
  ];
}
