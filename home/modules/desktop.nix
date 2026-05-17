{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  waybarConfigHome = "${config.home.homeDirectory}/.config/waybar";
  waybarOutput = osConfig.my.host.primaryMonitor;
  waybarOutputLine = lib.optionalString (waybarOutput != "") ''
    "output": ${builtins.toJSON waybarOutput},
  '';
  waybarTopConfig = pkgs.writeText "waybar-top.jsonc" ''
        {
          "layer": "top",
          "position": "top",
          "height": 32,
          "spacing": 6,
        "reload_style_on_change": true,
    ${waybarOutputLine}
        "include": [
          "${waybarConfigHome}/config/modules/groups.jsonc",
          "${waybarConfigHome}/config/modules/launchers.jsonc",
          "${waybarConfigHome}/config/modules/storage.jsonc",
          "${waybarConfigHome}/config/modules/system.jsonc",
          "${waybarConfigHome}/config/modules/power.jsonc",
          "${waybarConfigHome}/config/modules/workspaces.jsonc",
          "${waybarConfigHome}/config/modules/audio.jsonc",
          "${waybarConfigHome}/config/modules/connections.jsonc",
          "${waybarConfigHome}/config/modules/battery.jsonc",
          "${waybarConfigHome}/config/modules/clock.jsonc",
          "${waybarConfigHome}/config/modules/tray.jsonc"
        ],

          "modules-left": ["hyprland/workspaces"],
          "modules-center": [
            "clock",
            "group/distro-group",
            "group/storage",
            "group/system"
          ],
          "modules-right": [
            "tray",
            "power-profiles-daemon",
            "idle_inhibitor",
            "group/audio",
            "group/connections",
            "battery",
            "custom/power"
          ]
        }
  '';
  waybarSplashConfig = pkgs.writeText "waybar-splash.jsonc" ''
      {
        "layer": "bottom",
        "position": "bottom",
        "height": 180,
        "exclusive": false,
        "passthrough": true,
        "fixed-center": true,
        "reload_style_on_change": true,
    ${waybarOutputLine}
        "modules-center": ["custom/splash"],

        "custom/splash": {
          "format": "{}",
          "return-type": "json",
          "exec": "~/.config/waybar/scripts/splash.sh",
          "interval": "once",
          "tooltip": false
        }
      }
  '';
  waybarConfig = pkgs.runCommand "waybar-config" { } ''
    cp -R ${../../dotfiles/waybar} "$out"
    chmod -R u+w "$out"
    cp ${waybarTopConfig} "$out/config/top.jsonc"
    cp ${waybarSplashConfig} "$out/config/splash.jsonc"
  '';
in
{
  # ── Cursor ───────────────────────────────────────────────────────────────────

  home.pointerCursor = {
    name = "Bibata-Modern-Classic";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  xresources.properties = {
    "Xcursor.size" = 24;
    "Xft.dpi" = 96; # adjust to your display
  };

  # ── XDG ──────────────────────────────────────────────────────────────────────
  # Keeps your home directory clean.

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
  xdg.userDirs.setSessionVariables = false;

  # ── GTK ──────────────────────────────────────────────────────────────────────

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # ── Dotfile symlinks ──────────────────────────────────────────────────────────

  xdg.configFile = {
    "README-NIXOS-MANAGED.md".text = ''
      # Managed By NixOS

      This directory is the runtime config interface for desktop applications.

      Do not edit Home Manager-managed files here directly. Edit the source files
      in `/etc/nixos/dotfiles` or the relevant Home Manager module, then rebuild:

      ```sh
      sudo nixos-rebuild switch --flake /etc/nixos#laptop1
      ```

      App-created state that is not declared in Home Manager may still live here.
    '';
    "libinput-gestures.conf".source = ../../dotfiles/libinput-gestures.conf;
    hypr.source = ../../dotfiles/hypr;
    waybar.source = waybarConfig;
    rofi.source = ../../dotfiles/rofi;
    mako.source = ../../dotfiles/mako;
    eww.source = ../../dotfiles/eww;
    zed.source = ../../dotfiles/zed;
    wal.source = ../../dotfiles/wal;
    waypaper.source = ../../dotfiles/waypaper;
  };

  # ── Desktop packages (user-level) ────────────────────────────────────────────

  home.packages = with pkgs; [
    # Screenshot / screen tools
    grim
    slurp
    wl-clipboard
    hyprlock
    hypridle
    hyprsunset

    # Desktop daemons and controls
    waybar
    eww
    awww
    waypaper
    mako
    cliphist
    wl-clip-persist
    libinput-gestures
    playerctl
    polkit_gnome
    brightnessctl
    libnotify
    pavucontrol
    gnome-calendar
    gnome-clocks
    gnome-weather
    curl
    imagemagick

    # GTK / desktop integration
    adwaita-icon-theme
    gnome-themes-extra
    hicolor-icon-theme
    papirus-icon-theme
    shared-mime-info

    # Misc
    imv # image viewer
  ];

  # ── User services ───────────────────────────────────────────────────────────

  systemd.user.services = {
    polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "Polkit authentication agent";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    mako = {
      Unit = {
        Description = "Wayland notification daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.mako}/bin/mako";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypridle = {
      Unit = {
        Description = "Hyprland idle manager";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.hypridle}/bin/hypridle";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    waybar-top = {
      Unit = {
        Description = "Waybar top bar";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config/top.jsonc -s %h/.config/waybar/style/top.css";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    waybar-splash = {
      Unit = {
        Description = "Waybar splash overlay";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.waybar}/bin/waybar -c %h/.config/waybar/config/splash.jsonc -s %h/.config/waybar/style/splash.css";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    eww-daemon = {
      Unit = {
        Description = "Eww daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.eww}/bin/eww daemon --no-daemonize";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hyprsunset = {
      Unit = {
        Description = "Hyprland screen temperature daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.hyprsunset}/bin/hyprsunset";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    awww-daemon = {
      Unit = {
        Description = "Wayland wallpaper daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.awww}/bin/awww-daemon --quiet";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypr-restore-wallpaper = {
      Unit = {
        Description = "Restore Hyprland wallpaper";
        PartOf = [ "graphical-session.target" ];
        After = [
          "graphical-session.target"
          "awww-daemon.service"
        ];
        Wants = [ "awww-daemon.service" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "%h/.config/hypr/scripts/restore-wallpaper";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    hypr-power-profile-display = {
      Unit = {
        Description = "Apply display refresh rate from power profile";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "%h/.config/hypr/scripts/watch-power-profile-display";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    cliphist = {
      Unit = {
        Description = "Clipboard history";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    wl-clip-persist = {
      Unit = {
        Description = "Persist Wayland clipboard after source exits";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.wl-clip-persist}/bin/wl-clip-persist --clipboard regular";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    libinput-gestures = {
      Unit = {
        Description = "Touchpad gesture dispatcher";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${pkgs.libinput-gestures}/bin/libinput-gestures";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
