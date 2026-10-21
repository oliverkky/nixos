{
  fetchFromGitHub,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "infinity-icon-theme";
  version = "unstable-2023-12-07";

  src = fetchFromGitHub {
    owner = "rogts";
    repo = "infinity-icon-theme";
    rev = "55370c3a9076d0793c1157f6e667d79bd6f9f4b8";
    hash = "sha256-i3DpuO3/15nlmdm1tdnqJJgNSzA2YAY3PPpadDV2V9g=";
  };

  installPhase = ''
    runHook preInstall

    install -d $out/share/icons
    cp -r infinity infinity-dark $out/share/icons/

    runHook postInstall
  '';

  meta = {
    description = "Infinity and Infinity-Dark icon themes";
    homepage = "https://github.com/rogts/infinity-icon-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
