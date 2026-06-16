{
  config,
  lib,
  pkgs,
  ...
}:

let
  blenderRocm = pkgs.symlinkJoin {
    name = "blender-rocm";
    paths = [ pkgs.pkgsRocm.blender ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/blender"
      makeWrapper "${pkgs.pkgsRocm.blender}/bin/blender" "$out/bin/blender" \
        --set LD_PRELOAD "${pkgs.rocmPackages.llvm.llvm.lib}/lib/libLLVM.so.22.0"
    '';
  };
in
{
  options.my.nixos.desktop.packages.enable =
    lib.mkEnableOption "desktop packages and integration services";

  config = lib.mkIf config.my.nixos.desktop.packages.enable {
    # ── Fonts ─────────────────────────────────────────────────────────────────

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

    # ── Secret storage ────────────────────────────────────────────────────────
    # NetworkManager and desktop apps use this for saved credentials under
    # Hyprland, where no full GNOME/KDE session starts a keyring for us.

    services.gnome.gnome-keyring.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    programs.seahorse.enable = true;
    programs.dconf.enable = true;
    security.polkit.enable = true;

    # ── Printing ──────────────────────────────────────────────────────────────

    services.printing.enable = true;

    # Plain gsettings only searches $XDG_DATA_DIRS/glib-2.0/schemas. Nix stores
    # schemas under share/gsettings-schemas/<package>, so expose that root too.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    # ── Desktop packages ──────────────────────────────────────────────────────

    environment.systemPackages = with pkgs; [
      # Wayland compositor toolchain
      rofi
      glib
      gsettings-desktop-schemas

      # Theming
      bibata-cursors
      pywal16

      # File management
      nautilus
      file-roller
      evince
      gnome-disk-utility

      # Misc
      fastfetch
      obsidian
      brave
      blenderRocm
    ];
  };
}
