{
  config,
  lib,
  pkgs,
  ...
}:

let
  workstationHyprlandEnv = {
    AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:03:00.0-card";
    AQ_NO_MODIFIERS = "1";
    AQ_TRACE = "1";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };

  startHyprlandWorkstation = pkgs.writeShellApplication {
    name = "start-hyprland-workstation";
    text =
      lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: value: "export ${name}=${lib.escapeShellArg value}"
        ) workstationHyprlandEnv
      )
      + ''

        exec ${config.programs.hyprland.package}/bin/start-hyprland "$@"
      '';
  };

  hyprlandWorkstationSession = pkgs.writeTextFile {
    name = "hyprland-workstation-session";
    destination = "/share/wayland-sessions/hyprland-workstation.desktop";
    text = ''
      [Desktop Entry]
      Name=Hyprland Workstation
      Comment=Hyprland with workstation GPU workarounds
      Exec=${config.programs.uwsm.package}/bin/uwsm start -F -- ${startHyprlandWorkstation}/bin/start-hyprland-workstation
      Type=Application
      DesktopNames=Hyprland
    '';
    derivationArgs.passthru.providedSessions = [ "hyprland-workstation" ];
  };
in
{
  # The workstation has an RX 9070-class AMD GPU, a GTX 1050 Ti, and an AMD iGPU.
  # Prefer the discrete AMD card and leave the NVIDIA card unused for now.
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.blacklistedKernelModules = [
    "nouveau"
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  my.nixos.desktop.displayManager.wayland.enable = false;

  services.xserver.videoDrivers = [ "amdgpu" ];

  environment.sessionVariables = workstationHyprlandEnv;
  environment.systemPackages = [ startHyprlandWorkstation ];

  services.displayManager.sessionPackages = [ hyprlandWorkstationSession ];
  systemd.services.display-manager.environment = workstationHyprlandEnv;
}
