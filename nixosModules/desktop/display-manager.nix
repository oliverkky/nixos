{
  config,
  host,
  lib,
  pkgs,
  inputs,
  ...
}:

let
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

  options.my.nixos.desktop.displayManager = {
    enable = lib.mkEnableOption "SDDM desktop login";

    wayland.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run the SDDM greeter through its Wayland backend.";
    };
  };

  config = lib.mkIf config.my.nixos.desktop.displayManager.enable {
    # ── Display server ────────────────────────────────────────────────────────

    services.xserver.enable = true;
    services.xserver.xkb = {
      layout = "cz";
      variant = "";
    };

    # ── Display manager ───────────────────────────────────────────────────────
    # SDDM login. No desktop manager; Hyprland handles the user session.

    programs.silentSDDM = {
      enable = true;
      package = silentSddmPackage;
      theme = "default";
    };

    services.displayManager.sddm = {
      enable = true;
      wayland.enable = lib.mkForce config.my.nixos.desktop.displayManager.wayland.enable;
      settings.Theme = {
        CursorTheme = "Bibata-Modern-Classic";
        CursorSize = 24;
      };
    };
    security.pam.services.sddm.enableGnomeKeyring = true;

    systemd.tmpfiles.rules = [
      "d /var/lib/sddm-wallpaper 0755 root root -"
      "f ${silentSddmWallpaper} 0644 ${host.primaryUser} users -"
    ];
  };
}
