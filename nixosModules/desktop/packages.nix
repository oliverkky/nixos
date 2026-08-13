{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.desktop.packages = {
    enable = lib.mkEnableOption "desktop packages and integration services";
    printing.enable = lib.mkEnableOption "printer discovery and CUPS tools";
    networkDiscovery.enable = lib.mkEnableOption "mDNS discovery for desktop file and printer browsing";
  };

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
    services.gnome.localsearch.enable = true;
    services.gnome.tinysparql.enable = true;
    services.gvfs.enable = true;
    services.udisks2.enable = true;
    programs.seahorse.enable = true;
    programs.dconf.enable = true;
    security.polkit.enable = true;

    # ── Printing ──────────────────────────────────────────────────────────────

    services.printing = lib.mkIf config.my.nixos.desktop.packages.printing.enable {
      enable = true;
      browsed.enable = true;
    };
    services.avahi = lib.mkIf config.my.nixos.desktop.packages.networkDiscovery.enable {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Plain gsettings only searches $XDG_DATA_DIRS/glib-2.0/schemas. Nix stores
    # schemas under share/gsettings-schemas/<package>, so expose that root too.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
    ];

    # ── Network tools ─────────────────────────────────────────────────────────

    programs.wireshark.enable = true;

    # ── Desktop packages ──────────────────────────────────────────────────────

    environment.systemPackages =
      with pkgs;
      [
        # Wayland compositor toolchain
        glib
        gsettings-desktop-schemas

        # Theming
        bibata-cursors

        # File management
        nautilus
        file-roller
        evince
        gnome-disk-utility
        snapshot

        # Network analysis
        bettercap
        wireshark
        net-tools
      ]
      ++ lib.optionals config.my.nixos.desktop.packages.printing.enable [
        system-config-printer
      ]
      ++ lib.optionals config.my.nixos.desktop.packages.networkDiscovery.enable [
        wsdd
      ];
  };
}
