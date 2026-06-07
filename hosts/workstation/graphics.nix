{ lib, ... }:

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

  environment.sessionVariables = {
    AQ_DRM_DEVICES = "/dev/dri/by-path/pci-0000:03:00.0-card";
    AQ_NO_MODIFIERS = "1";
    LIBVA_DRIVER_NAME = "radeonsi";
    VDPAU_DRIVER = "radeonsi";
  };
}
