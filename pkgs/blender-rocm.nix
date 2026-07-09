{
  makeWrapper,
  pkgsRocm,
  rocmPackages,
  symlinkJoin,
}:

symlinkJoin {
  name = "blender-rocm";
  paths = [ pkgsRocm.blender ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    rm "$out/bin/blender"
    makeWrapper "${pkgsRocm.blender}/bin/blender" "$out/bin/blender" \
      --set LD_PRELOAD "${rocmPackages.llvm.llvm.lib}/lib/libLLVM.so.22.0"
  '';
}
