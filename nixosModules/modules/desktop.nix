{ config, pkgs, ... }:

{
  # ── Display server ───────────────────────────────────────────────────────────

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "cz";
    variant = "";
  };

  # ── Display manager ──────────────────────────────────────────────────────────
  # SDDM with Wayland support. No desktop manager — Hyprland handles the session.

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  security.pam.services.sddm.enableGnomeKeyring = true;

  # ── Hyprland ─────────────────────────────────────────────────────────────────

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # ── Fonts ────────────────────────────────────────────────────────────────────

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      nerd-fonts.noto
      nerd-fonts.jetbrains-mono
    ];
    fontconfig.defaultFonts = {
      monospace = [ "JetBrainsMono Nerd Font" ];
      sansSerif = [ "Noto Sans" ];
      serif = [ "Noto Serif" ];
    };
  };

  # ── Cursor ───────────────────────────────────────────────────────────────────

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE = "24";
  };

  # ── Graphics & Wayland libs ──────────────────────────────────────────────────
  # Use nix-ld instead of a global LD_LIBRARY_PATH.
  # This lets dynamically-linked binaries (e.g. downloaded AppImages, Zed
  # plugins, Python wheels with native extensions) find system libs without
  # poisoning every process's linker search path.

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

  # ── Bluetooth ────────────────────────────────────────────────────────────────

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
  services.power-profiles-daemon.enable = true;

  # ── Secret storage ───────────────────────────────────────────────────────────
  # NetworkManager and desktop apps use this for saved credentials under
  # Hyprland, where no full GNOME/KDE session starts a keyring for us.

  services.gnome.gnome-keyring.enable = true;
  programs.seahorse.enable = true;

  # ── Printing ─────────────────────────────────────────────────────────────────

  services.printing.enable = true;

  # ── Desktop packages ─────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    # Wayland compositor toolchain
    kitty
    rofi
    waybar
    eww
    awww
    waypaper
    networkmanagerapplet
    brightnessctl
    grim
    slurp
    wl-clipboard
    libnotify
    pavucontrol
    hyprlock

    # Theming
    bibata-cursors
    pywal16

    # File management
    nautilus

    file-roller
    unzip

    # Bluetooth GUI
    overskride

    # Misc
    fastfetch
    obsidian
    brave
  ];
}
