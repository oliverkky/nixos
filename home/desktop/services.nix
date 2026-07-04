{
  config,
  lib,
  pkgs,
  ...
}:

let
  hyprScripts = config.my.home.desktop.scripts.hyprPackage;
  quickshellRuntimeInit = pkgs.writeShellScript "quickshell-runtime-init" ''
    runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
    osd_dir="$runtime_dir/quickshell-osd"

    mkdir -p "$osd_dir"
    if [ ! -f "$osd_dir/state.json" ]; then
      printf '{"visible":false,"icon":"","text":"","value":0}\n' > "$osd_dir/state.json"
    fi
  '';
in
{
  options.my.home.desktop.services.enable = lib.mkEnableOption "desktop user services";

  config = lib.mkIf config.my.home.desktop.services.enable {
    xdg.configFile."systemd/user/app-polkit\\x2dgnome\\x2dauthentication\\x2dagent\\x2d1@autostart.service".source =
      config.lib.file.mkOutOfStoreSymlink "/dev/null";

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

      quickshell = {
        Unit = {
          Description = "Quickshell desktop shell";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStartPre = "${quickshellRuntimeInit}";
          ExecStart = "${pkgs.quickshell}/bin/quickshell -p %h/.config/quickshell";
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
          ExecStart = "${hyprScripts}/bin/restore-wallpaper";
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
          ExecStart = "${hyprScripts}/bin/watch-power-profile-display";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      hypr-battery-profile = {
        Unit = {
          Description = "Switch to power saver on low battery";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${hyprScripts}/bin/watch-battery-profile";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      bluetooth-auto-power-save = {
        Unit.Description = "Power off idle Bluetooth while on battery";
        Service = {
          Type = "oneshot";
          ExecStart = "${hyprScripts}/bin/bluetooth-auto-power-save";
        };
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
    };

    systemd.user.timers.bluetooth-auto-power-save = {
      Unit.Description = "Periodically power off idle Bluetooth while on battery";
      Timer = {
        OnBootSec = "10min";
        OnUnitActiveSec = "10min";
        Unit = "bluetooth-auto-power-save.service";
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
