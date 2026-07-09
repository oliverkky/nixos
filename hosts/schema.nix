{ lib, ... }:

let
  monitorType = lib.types.submodule {
    options = {
      output = lib.mkOption {
        type = lib.types.str;
        description = "Hyprland output name.";
      };
      mode = lib.mkOption {
        type = lib.types.str;
        description = "Monitor mode, for example 2560x1440@75.";
      };
      position = lib.mkOption {
        type = lib.types.str;
        description = "Hyprland monitor position, for example 0x0.";
      };
      scale = lib.mkOption {
        type = lib.types.number;
        description = "Hyprland monitor scale.";
      };
    };
  };
in
{
  options = {
    battery.chargeType = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional firmware battery charge mode.";
    };

    cursor = {
      name = lib.mkOption { type = lib.types.str; };
      size = lib.mkOption { type = lib.types.ints.positive; };
      dpi = lib.mkOption { type = lib.types.ints.positive; };
    };

    hostName = lib.mkOption { type = lib.types.str; };

    home = {
      desktop.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      development.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      shell.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      audioProduction.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };

    hyprland.drmDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional DRM device path used by host-specific Hyprland workarounds.";
    };

    monitors = lib.mkOption {
      type = lib.types.nonEmptyListOf monitorType;
      description = "Hyprland monitor layout.";
    };

    primaryMonitor = lib.mkOption { type = lib.types.str; };

    primaryUser = lib.mkOption { type = lib.types.str; };
    primaryUserDescription = lib.mkOption {
      type = lib.types.str;
      default = "Oliver Klinkovsky";
    };
    primaryUid = lib.mkOption { type = lib.types.ints.positive; };
    primaryGid = lib.mkOption { type = lib.types.ints.positive; };

    reaper = {
      pipewireLatency = lib.mkOption { type = lib.types.str; };
    };

    secondaryMonitor = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    secondaryMonitorWorkspace = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
    };

    stateVersion = lib.mkOption { type = lib.types.str; };
    system = lib.mkOption {
      type = lib.types.enum [ "x86_64-linux" ];
      description = "Nix system for this host.";
    };

    vcvRack.pipewireLatency = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    zed.audioDevice = lib.mkOption { type = lib.types.str; };
  };
}
