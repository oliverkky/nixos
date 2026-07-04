{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.nixos.guest;
in
{
  options.my.nixos.guest = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to provide an unprivileged ephemeral guest account.";
    };

    userName = lib.mkOption {
      type = lib.types.str;
      default = "guest";
      description = "Name of the ephemeral guest account.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1500;
      description = "UID assigned to the guest account.";
    };

    homeSize = lib.mkOption {
      type = lib.types.str;
      default = "2G";
      description = "Maximum size of the tmpfs-backed guest home directory.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.userName} = {
      isNormalUser = true;
      description = "Guest";
      uid = cfg.uid;
      group = "users";
      extraGroups = [
        "audio"
        "video"
        "render"
      ];
      home = "/home/${cfg.userName}";
      createHome = true;
      hashedPassword = "";
      shell = pkgs.zsh;
    };

    fileSystems."/home/${cfg.userName}" = {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [
        "mode=0700"
        "uid=${toString cfg.uid}"
        "gid=100"
        "size=${cfg.homeSize}"
        "nosuid"
        "nodev"
      ];
    };

    security.pam.services = {
      login.allowNullPassword = true;
      sddm.allowNullPassword = true;
    };
  };
}
