{
  config,
  host,
  lib,
  pkgs,
  ...
}:

let
  pipewireLatency = host.vcvRack.pipewireLatency or (host.reaper.pipewireLatency or "128/48000");
  vcvRackPackage = pkgs.vcv-rack.overrideAttrs (_old: {
    # nixpkgs fetches a deleted upstream PR patch on Linux.
    # Drop this once pkgs.vcv-rack no longer references PR 1944.
    patches = [
      (pkgs.path + "/pkgs/by-name/vc/vcv-rack/rack-minimize-vendoring.patch")
      (pkgs.writeText "vcv-rack-fix-plugin-build-order.patch" ''
        diff --git a/Makefile b/Makefile
        index 1d6accc6..069fc8ce 100644
        --- a/Makefile
        +++ b/Makefile
        @@ -160,7 +160,7 @@ build/%.res: %.rc


         # Plugin helper
        -plugins:
        +plugins: all
         ifdef CMD
         	for f in plugins/*; do (cd "$$f" && $(CMD)); done
         else
      '')
    ];

    postPatch = ''
      substituteInPlace src/window/Window.cpp \
        --replace-fail \
          '	XkbStateRec state;
      	XkbGetState(display, XkbUseCoreKbd, &state);

      	// Derived from GLFW'"'"'s translateState() from x11_window.c
      	if (state.mods & ShiftMask)
      		mods |= GLFW_MOD_SHIFT;
      	if (state.mods & ControlMask)
      		mods |= GLFW_MOD_CONTROL;
      	if (state.mods & Mod1Mask)
      		mods |= GLFW_MOD_ALT;
      	if (state.mods & Mod4Mask)
      		mods |= GLFW_MOD_SUPER;
      	if (state.mods & LockMask)
      		mods |= GLFW_MOD_CAPS_LOCK;
      	if (state.mods & Mod2Mask)
      		mods |= GLFW_MOD_NUM_LOCK;
      #else' \
          '	if (display) {
      		XkbStateRec state;
      		XkbGetState(display, XkbUseCoreKbd, &state);

      		// Derived from GLFW'"'"'s translateState() from x11_window.c
      		if (state.mods & ShiftMask)
      			mods |= GLFW_MOD_SHIFT;
      		if (state.mods & ControlMask)
      			mods |= GLFW_MOD_CONTROL;
      		if (state.mods & Mod1Mask)
      			mods |= GLFW_MOD_ALT;
      		if (state.mods & Mod4Mask)
      			mods |= GLFW_MOD_SUPER;
      		if (state.mods & LockMask)
      			mods |= GLFW_MOD_CAPS_LOCK;
      		if (state.mods & Mod2Mask)
      			mods |= GLFW_MOD_NUM_LOCK;
      		return mods;
      	}
      #endif'

      substituteInPlace src/window/Window.cpp \
        --replace-fail \
          '	if (glfwGetKey(win, GLFW_KEY_LEFT_SUPER) == GLFW_PRESS || glfwGetKey(win, GLFW_KEY_RIGHT_SUPER) == GLFW_PRESS)
      		mods |= GLFW_MOD_SUPER;
      #endif' \
          '	if (glfwGetKey(win, GLFW_KEY_LEFT_SUPER) == GLFW_PRESS || glfwGetKey(win, GLFW_KEY_RIGHT_SUPER) == GLFW_PRESS)
      		mods |= GLFW_MOD_SUPER;'
    '';

    postInstall = ''
      mv \
        "$out/share/vcv-rack/Fundamental.vcvplugin" \
        "$out/share/vcv-rack/Fundamental-2.6.4-lin-x64.vcvplugin"
    '';
  });
  vcvRack = pkgs.symlinkJoin {
    name = "vcv-rack-pipewire-jack";
    paths = [
      vcvRackPackage
      pkgs.pipewire.jack
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm "$out/bin/Rack"
      makeWrapper "${pkgs.pipewire.jack}/bin/pw-jack" "$out/bin/Rack" \
        --add-flags "${vcvRackPackage}/bin/Rack" \
        --set GLFW_PLATFORM x11 \
        --set PIPEWIRE_LATENCY "${pipewireLatency}"

      rm "$out/share/applications/vcv-rack.desktop"
      cp "${vcvRackPackage}/share/applications/vcv-rack.desktop" "$out/share/applications/vcv-rack.desktop"
      substituteInPlace "$out/share/applications/vcv-rack.desktop" \
        --replace-fail 'Exec=Rack' "Exec=$out/bin/Rack"
    '';
  };
in
{
  options.my.home.desktop.vcv-rack.enable = lib.mkEnableOption "VCV Rack";

  config = lib.mkIf config.my.home.desktop.vcv-rack.enable {
    home.packages = [ vcvRack ];
  };
}
