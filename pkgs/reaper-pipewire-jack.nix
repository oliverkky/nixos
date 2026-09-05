{
  lib,
  makeWrapper,
  pipewire,
  reaper,
  symlinkJoin,
}:

{
  lv2Path,
  pipewireLatency,
}:

symlinkJoin {
  name = "reaper-pipewire-jack";
  paths = [
    reaper
    pipewire.jack
  ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm "$out/bin/reaper"
    makeWrapper "${pipewire.jack}/bin/pw-jack" "$out/bin/reaper" \
      --add-flags "${reaper}/bin/reaper" \
      --run "source /etc/set-environment" \
      --prefix LD_LIBRARY_PATH : /run/current-system/sw/share/nix-ld/lib \
      --set PIPEWIRE_LATENCY "${lib.escapeShellArg pipewireLatency}" \
      --prefix LV2_PATH : "${lib.escapeShellArg lv2Path}"
  '';
}
