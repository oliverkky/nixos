{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  zedSettings = builtins.replaceStrings [ "__ZED_AUDIO_DEVICE__" ] [ host.zed.audioDevice ] (
    builtins.readFile ../../dotfiles/zed/settings.json
  );
  zedConfig = pkgs.runCommandLocal "hm-zed-config" { } ''
    mkdir -p "$out"
    cp ${../../dotfiles/zed/keymap.json} "$out/keymap.json"
    cp ${pkgs.writeText "zed-settings.json" zedSettings} "$out/settings.json"
  '';
in

{
  options.my.home.desktop.dotfiles.enable = lib.mkEnableOption "desktop dotfile links";

  config = lib.mkIf config.my.home.desktop.dotfiles.enable {
    xdg.configFile = {
      "README-NIXOS-MANAGED.md".text = ''
        # Managed By NixOS

        This directory is the runtime config interface for desktop applications.

        Do not edit Home Manager-managed files here directly. Edit the source files
        in `/etc/nixos/dotfiles` or the relevant Home Manager module, then rebuild:

        ```sh
        sudo nixos-rebuild switch --flake /etc/nixos#${host.hostName}
        ```

        App-created state that is not declared in Home Manager may still live here.
      '';
      hypr.source = ../../dotfiles/hypr;
      quickshell.source = ../../dotfiles/quickshell;
      rofi.source = ../../dotfiles/rofi;
      zed.source = zedConfig;
      wal.source = ../../dotfiles/wal;
      waypaper.source = ../../dotfiles/waypaper;
    };
  };
}
