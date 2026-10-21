{
  fetchFromGitHub,
  kdePackages,
  lib,
  stdenvNoCC,
}:

let
  rogtsIcons = fetchFromGitHub {
    owner = "rogts";
    repo = "infinity-icon-theme";
    rev = "55370c3a9076d0793c1157f6e667d79bd6f9f4b8";
    hash = "sha256-i3DpuO3/15nlmdm1tdnqJJgNSzA2YAY3PPpadDV2V9g=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "infinity-icon-theme";
  version = "0.4.7";

  src = ./infinity-glass-icon-theme-0.4.7.tar.gz;
  sourceRoot = "Infinity";

  propagatedBuildInputs = [ kdePackages.breeze-icons ];
  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    install -d $out/share/icons
    cp -r . $out/share/icons/Infinity
    cp -r ${rogtsIcons}/infinity-dark $out/share/icons/Infinity-Dark
    ln -s ${kdePackages.breeze-icons}/share/icons/breeze $out/share/icons/breeze
    ln -s ${kdePackages.breeze-icons}/share/icons/breeze-dark $out/share/icons/breeze-dark

    # Drop upstream aliases whose targets are absent from both icon sets.
    chmod -R u+w $out/share/icons/Infinity-Dark
    find $out/share/icons/Infinity-Dark -xtype l -delete

    runHook postInstall
  '';

  meta = {
    description = "Infinity Glass icon theme";
    homepage = "https://www.gnome-look.org/p/2112373";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
