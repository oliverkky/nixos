{
  appimage-run,
  cacert,
  fetchurl,
  gtk3,
  lib,
  libsoup_3,
  makeWrapper,
  stdenvNoCC,
  webkitgtk_4_1,
}:

let
  version = "2.4.2";
  appimage = fetchurl {
    url = "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${version}.AppImage";
    hash = "sha256-0S+4yOrBrs0t+2N3rNSPmU+PpDntUpL6Uy3YKIDwKf0=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "orca-slicer-appimage";
  inherit version;

  dontUnpack = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${appimage} $out/share/orca-slicer/OrcaSlicer.AppImage
    makeWrapper ${appimage-run}/bin/appimage-run $out/bin/orca-slicer \
      --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          gtk3
          libsoup_3
          webkitgtk_4_1
        ]
      } \
      --add-flags $out/share/orca-slicer/OrcaSlicer.AppImage

    install -Dm644 /dev/stdin $out/share/applications/orca-slicer.desktop <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=OrcaSlicer
    Comment=G-code generator for 3D printers
    Exec=orca-slicer %F
    Icon=orca-slicer
    Terminal=false
    Categories=Graphics;3DGraphics;Engineering;
    MimeType=model/stl;model/3mf;application/vnd.ms-3mfdocument;
    StartupWMClass=orca-slicer
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Official OrcaSlicer AppImage wrapped for NixOS";
    homepage = "https://github.com/OrcaSlicer/OrcaSlicer";
    changelog = "https://github.com/OrcaSlicer/OrcaSlicer/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
    mainProgram = "orca-slicer";
    platforms = [ "x86_64-linux" ];
  };
}
