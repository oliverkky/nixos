{
  lib,
  gnumake,
  hyprlandPlugins,
  pkg-config,
  src,
  wayland,
  wayland-scanner,
}:

hyprlandPlugins.mkHyprlandPlugin (finalAttrs: {
  pluginName = "hyprglass";
  version = "0.9.1";
  inherit src;

  nativeBuildInputs = [
    gnumake
    pkg-config
    wayland
    wayland-scanner
  ];

  dontUseCmakeConfigure = true;
  makeFlags = [ "HYPRGLASS_VERSION=${finalAttrs.version}" ];
  installPhase = ''
    runHook preInstall
    install -Dm755 hyprglass.so "$out/lib/libhyprglass.so"
    runHook postInstall
  '';

  meta = {
    description = "Liquid glass rendering plugin for Hyprland";
    homepage = "https://github.com/hyprnux/hyprglass";
    platforms = lib.platforms.linux;
  };
})
