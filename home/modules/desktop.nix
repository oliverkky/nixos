{ config, pkgs, ... }:

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
    cursorTheme = {
      name = "Bibata-Modern-Classic";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  # ── Dotfile symlinks ──────────────────────────────────────────────────────────

  xdg.configFile = {
    hypr.source = ../../dotfiles/hypr;
    waybar.source = ../../dotfiles/waybar;
    rofi.source = ../../dotfiles/rofi;
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

    # Misc
    imv # image viewer
  ];
}
