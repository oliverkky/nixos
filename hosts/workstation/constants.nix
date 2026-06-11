{
  hostName = "workstation";
  monitors = [
    {
      output = "DP-1";
      mode = "2560x1440@75";
      position = "0x0";
      scale = 1.0;
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
  reaper = {
    uiScale = 1.0;
    pipewireLatency = "128/48000";
  };
  secondaryMonitor = "HDMI-A-1";
  secondaryMonitorWorkspace = 10;
  stateVersion = "26.05";
}
