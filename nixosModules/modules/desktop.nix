{
  config,
  pkgs,
  inputs,
  ...
}:

let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
  hyprlandVersion = pkgs.lib.removeSuffix "\n" (builtins.readFile "${inputs.hyprland}/VERSION");
  hyprlandPackage = hyprlandPackages.hyprland.overrideAttrs {
    src = inputs.hyprland;
    env = {
      GIT_COMMITS = 0;
      GIT_COMMIT_DATE = inputs.hyprland.lastModifiedDate or "";
      GIT_COMMIT_HASH = inputs.hyprland.rev or "";
      GIT_DIRTY = "clean";
      GIT_TAG = "v${hyprlandVersion}";
    };
  };
  silentSddmWallpaper = "/var/lib/sddm-wallpaper/current-wallpaper.png";
  silentSddmPackage =
    inputs.silentSDDM.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        installPhase = old.installPhase + ''
          ln -sfn ${silentSddmWallpaper} $out/share/sddm/themes/silent/backgrounds/hypr-current.png
          substituteInPlace $out/share/sddm/themes/silent/configs/default.conf \
            --replace-fail 'background = "smoky.jpg"' 'background = "hypr-current.png"'
        '';
      });
in

{
  imports = [
    inputs.silentSDDM.nixosModules.default
  ];

  # ── Display server ───────────────────────────────────────────────────────────

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "cz";
    variant = "";
  };

  # ── Display manager ──────────────────────────────────────────────────────────
  # SDDM with Wayland support. No desktop manager — Hyprland handles the session.

  programs.silentSDDM = {
    enable = true;
    package = silentSddmPackage;
    theme = "default";
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = pkgs.lib.mkForce true;
    settings.Theme = {
      CursorTheme = "Bibata-Modern-Classic";
      CursorSize = 24;
    };
  };
  security.pam.services.sddm.enableGnomeKeyring = true;

  # ── Hyprland ─────────────────────────────────────────────────────────────────

  programs.hyprland = {
    enable = true;
    package = hyprlandPackage;
    portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
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
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  programs.seahorse.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;

  # ── Printing ─────────────────────────────────────────────────────────────────

  services.printing.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/sddm-wallpaper 0755 root root -"
    "f ${silentSddmWallpaper} 0644 oliver users -"
  ];

  # Plain gsettings only searches $XDG_DATA_DIRS/glib-2.0/schemas. Nix stores
  # schemas under share/gsettings-schemas/<package>, so expose that root too.
  environment.sessionVariables.XDG_DATA_DIRS = [
    "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
  ];

  # ── Desktop packages ─────────────────────────────────────────────────────────

  environment.systemPackages = with pkgs; [
    # Wayland compositor toolchain
    kitty
    rofi
    waybar
    gjs
    gtk4
    libadwaita
    glib
    gsettings-desktop-schemas
    imagemagick
    eww
    awww
    waypaper
    networkmanagerapplet
    brightnessctl
    grim
    slurp
    wl-clipboard
    libnotify
    polkit_gnome
    pavucontrol
    hypridle
    hyprlock
    hyprsunset
    hyprshot
    hyprshutdown

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
