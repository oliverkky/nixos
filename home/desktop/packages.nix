{
  config,
  lib,
  pkgs,
  ...
}:

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
      audioProduction.enable = lib.mkDefault true;
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
        waypaper
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
        fastfetch
        gnome-calendar
        gnome-clocks
        gnome-weather
        libreoffice
        lmstudio
        mission-center
        obs-studio
        obsidian
        prismlauncher
        thunderbird
      ]
      ++ lib.optionals config.my.home.desktop.packages.audioProduction.enable [
        carla
        crosspipe
        neural-amp-modeler-lv2
        qpwgraph
        raysession
      ];
  };

}
