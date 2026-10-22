{
  fetchFromGitHub,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "frost-icon-theme-source";
  version = "0.3.1-unstable-2026-10-21";

  src = fetchFromGitHub {
    owner = "thissayantan";
    repo = "frost-icon-theme";
    rev = "40656dec2d235c2518a62a6876dec457733b0644";
    hash = "sha256-mL/0oW2juaI1lSjNci4E8Aty2/RUXQhF1XMhzsFqSio=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/frost"
    cp -R src "$out/share/frost/"
    install -Dm644 docs/DESIGN.md "$out/share/frost/docs/DESIGN.md"
    runHook postInstall
  '';
}
