{
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

  # ── Display server ───────────────────────────────────────────────────────────

  services.xserver.enable = true;
  services.xserver.xkb = {
    layout = "cz";
    variant = "";
  };

  # ── Display manager ──────────────────────────────────────────────────────────
  # SDDM with Wayland support. No desktop manager; Hyprland handles the session.

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

  systemd.tmpfiles.rules = [
    "d /var/lib/sddm-wallpaper 0755 root root -"
    "f ${silentSddmWallpaper} 0644 oliver users -"
  ];
}
