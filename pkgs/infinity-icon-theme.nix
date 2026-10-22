{
  kdePackages,
  lib,
  stdenvNoCC,
}:

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

    runHook postInstall
  '';

  meta = {
    description = "Infinity Glass icon theme";
    homepage = "https://www.gnome-look.org/p/2112373";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
