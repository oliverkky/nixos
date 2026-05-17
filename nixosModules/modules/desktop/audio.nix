{ pkgs, ... }:

{
  # ── Graphics & Wayland libs ──────────────────────────────────────────────────
  # Use nix-ld instead of a global LD_LIBRARY_PATH.
  # This lets dynamically-linked binaries find system libs without poisoning
  # every process's linker search path.

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      wayland
      libxkbcommon
      mesa
      libGL
      vulkan-loader
    ];
  };

  # ── Sound ────────────────────────────────────────────────────────────────────

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
