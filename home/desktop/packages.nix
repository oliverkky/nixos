{
  config,
  host ? null,
  lib,
  pkgs,
  ...
}:

let
  orcaSlicer =
    if host != null && host.hostName == "workstation" then
      pkgs.callPackage ../../pkgs/orca-slicer-egl.nix { }
    else
      pkgs.orca-slicer;
in
{
  options.my.home.desktop.packages = {
    enable = lib.mkEnableOption "desktop user packages";
    apps.enable = lib.mkEnableOption "desktop applications";
    audioProduction.enable = lib.mkEnableOption "audio production applications";
    runtime.enable = lib.mkEnableOption "desktop runtime tools";
  };

  config = lib.mkIf config.my.home.desktop.packages.enable {
    my.home.desktop.packages = {
      apps.enable = lib.mkDefault true;
      audioProduction.enable = lib.mkDefault false;
      runtime.enable = lib.mkDefault true;
    };

    home.packages =
      with pkgs;
      lib.optionals config.my.home.desktop.packages.runtime.enable [
        grim
        slurp
        wl-clipboard
        hyprlock
        hypridle
        hyprsunset
        quickshell
        awww
        wallutils
        waypaper
        rofi
        pywal16
        cliphist
        wl-clip-persist
        playerctl
        brightnessctl
        libnotify
        pavucontrol
        curl
        imagemagick
        ffmpeg
        adwaita-icon-theme
        gnome-themes-extra
        hicolor-icon-theme
        papirus-icon-theme
        shared-mime-info
        imv
      ]
      ++ lib.optionals config.my.home.desktop.packages.apps.enable [
        brave
        discord
        fastfetch
        gnome-calendar
        gnome-clocks
        gnome-weather
        libreoffice
        lmstudio
        mission-center
        obs-studio
        obsidian
        orcaSlicer
        prismlauncher
        remmina
        freerdp
        showtime
        thunderbird
        vlc
        gimp
      ]
      ++ lib.optionals config.my.home.desktop.packages.audioProduction.enable [
        carla
        crosspipe
        neural-amp-modeler-lv2
        qpwgraph
        raysession
        wineWow64Packages.yabridge
        winetricks
        yabridge
        yabridgectl
      ];
  };

}
