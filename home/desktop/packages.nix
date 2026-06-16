{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.home.desktop.packages.enable = lib.mkEnableOption "desktop user packages";

  config = lib.mkIf config.my.home.desktop.packages.enable {
    home.packages = with pkgs; [
      # Screenshot / screen tools
      grim
      slurp
      wl-clipboard
      hyprlock
      hypridle
      hyprsunset

      # Desktop daemons and controls
      quickshell
      awww
      waypaper
      mako
      cliphist
      wl-clip-persist
      playerctl
      polkit_gnome
      brightnessctl
      libnotify
      pavucontrol
      gnome-calendar
      gnome-clocks
      gnome-weather
      mission-center
      curl
      imagemagick
      ffmpeg
      prismlauncher
      lmstudio

      # Audio production
      qpwgraph
      crosspipe
      carla
      raysession
      neural-amp-modeler-lv2

      # GTK / desktop integration
      adwaita-icon-theme
      gnome-themes-extra
      hicolor-icon-theme
      papirus-icon-theme
      shared-mime-info

      # Misc
      imv # image viewer
    ];
  };
}
