{
  hostName = "workstation";
  system = "x86_64-linux";
  home = {
    audioProduction.enable = true;
    desktop.enable = true;
    development.enable = true;
    shell.enable = true;
  };
  cursor = {
    name = "Bibata-Modern-Classic";
    size = 24;
    dpi = 96;
  };
  hyprland.drmDevice = "/dev/dri/card1";
  monitors = [
    {
      output = "DP-1";
      mode = "2560x1440@74.97Hz";
      position = "0x0";
      scale = 1.0;
      hdr.enable = true;
    }
    {
      output = "HDMI-A-1";
      mode = "1920x1080@60";
      position = "2560x180";
      scale = 1.0;
    }
  ];
  primaryMonitor = "DP-1";
  primaryUser = "oliver";
  primaryUserDescription = "Oliver Klinkovský";
  primaryUid = 1000;
  primaryGid = 100;
  reaper = {
    pipewireLatency = "128/48000";
  };
  secondaryMonitor = "HDMI-A-1";
  secondaryMonitorWorkspace = 10;
  zed.audioDevice = "alsa:default";
  stateVersion = "26.05";
}
