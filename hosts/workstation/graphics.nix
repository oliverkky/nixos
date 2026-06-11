{
  config,
  lib,
  pkgs,
  ...
}:

let
  workstationHyprlandEnv = {
    # Aquamarine uses ':' as the AQ_DRM_DEVICES separator, so the PCI by-path
    # symlink is not usable here because it contains ':' characters.
    AQ_DRM_DEVICES = "/dev/dri/card1";
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
  # The workstation has an RX 9070-class AMD GPU and an AMD iGPU.
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.rocblas
      rocmPackages.hipblas
    ];
  };
  hardware.enableRedistributableFirmware = lib.mkDefault true;

  my.nixos.desktop.displayManager.wayland.enable = false;

  services.xserver.videoDrivers = [ "amdgpu" ];

  environment.sessionVariables = workstationHyprlandEnv;
  environment.systemPackages = with pkgs; [
    startHyprlandWorkstation
    rocmPackages.hipcc
    rocmPackages.rocminfo
    rocmPackages.rocm-smi
  ];

  services.displayManager.sessionPackages = [ hyprlandWorkstationSession ];
  systemd.services.display-manager.environment = workstationHyprlandEnv;
}
