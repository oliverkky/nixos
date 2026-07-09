{
  hostName = "laptop1";
  system = "x86_64-linux";
  home = {
    audioProduction.enable = true;
    desktop.enable = true;
    development.enable = true;
    shell.enable = true;
  };
  battery.chargeType = "Standard";
  cursor = {
    name = "Bibata-Modern-Classic";
    size = 24;
    dpi = 96;
  };
  monitors = [
    {
      output = "eDP-1";
      mode = "2880x1800@60";
      position = "0x0";
      scale = 1.5;
    }
  ];
  primaryMonitor = "eDP-1";
  primaryUser = "oliver";
  primaryUserDescription = "Oliver Klinkovský";
  primaryUid = 1000;
  primaryGid = 100;
  reaper = {
    pipewireLatency = "64/48000";
  };
  zed.audioDevice = "alsa:default";
  stateVersion = "24.11";
}
