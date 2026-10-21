{ stdenv }:

stdenv.mkDerivation {
  pname = "steam-ui-scale";
  version = "1.0";
  src = ./steam-ui-scale.c;

  dontUnpack = true;
  buildPhase = ''
    runHook preBuild
    $CC -shared -fPIC -O2 -Wall -Wextra -Werror -Wl,-z,relro,-z,now \
      -o libsteam-ui-scale.so "$src" -ldl -lm
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    install -Dm755 libsteam-ui-scale.so "$out/lib/libsteam-ui-scale.so"
    runHook postInstall
  '';
}
