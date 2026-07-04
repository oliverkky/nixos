{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) makeBinPath;

  hyprRuntimeInputs = with pkgs; [
    awww
    bash
    bluez
    brightnessctl
    coreutils
    dbus
    gawk
    gnugrep
    gnused
    hyprland
    imagemagick
    jq
    kitty
    power-profiles-daemon
    pywal16
    waypaper
  ];

  rofiRuntimeInputs = with pkgs; [
    bash
    bluez
    brave
    brightnessctl
    cliphist
    coreutils
    gawk
    glib
    gnugrep
    gnused
    grim
    hyprland
    hyprlock
    jq
    kitty
    libnotify
    networkmanager
    pavucontrol
    power-profiles-daemon
    procps
    python3
    rofi
    slurp
    systemd
    wireplumber
    wl-clipboard
    xdg-utils
  ];

  makeScriptSet =
    {
      name,
      src,
      runtimeInputs,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name src;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall

        mkdir -p "$out/bin" "$out/libexec/${name}"
        cp -R . "$out/libexec/${name}/"
        chmod -R u+rwX,go+rX "$out/libexec/${name}"

        for script in "$out/libexec/${name}"/*; do
          [ -f "$script" ] || continue
          chmod +x "$script"
          makeWrapper "$script" "$out/bin/$(basename "$script")" \
            --prefix PATH : ${lib.escapeShellArg (makeBinPath runtimeInputs)}
        done

        runHook postInstall
      '';
    };

  hyprScripts = makeScriptSet {
    name = "hypr-desktop-scripts";
    src = ../../dotfiles/hypr/scripts;
    runtimeInputs = hyprRuntimeInputs;
  };

  rofiScripts = makeScriptSet {
    name = "rofi-control-scripts";
    src = ../../dotfiles/rofi/scripts;
    runtimeInputs = rofiRuntimeInputs;
  };
in
{
  options.my.home.desktop.scripts = {
    enable = lib.mkEnableOption "packaged desktop helper scripts";

    hyprPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Store package containing Hyprland helper scripts.";
    };

    rofiPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Store package containing rofi helper scripts.";
    };
  };

  config = lib.mkIf config.my.home.desktop.scripts.enable {
    my.home.desktop.scripts = {
      hyprPackage = hyprScripts;
      rofiPackage = rofiScripts;
    };

    home.packages = [
      hyprScripts
      rofiScripts
    ];

    home.sessionVariables = {
      HYPR_SCRIPT_DIR = "${hyprScripts}/bin";
      ROFI_SCRIPT_DIR = "${rofiScripts}/bin";
      HYPR_SET_POWER_PROFILE_DISPLAY = "${hyprScripts}/bin/set-power-profile-display";
    };
  };
}
