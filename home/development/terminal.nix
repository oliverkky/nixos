{
  config,
  lib,
  ...
}:

{
  options.my.home.development.terminal.enable = lib.mkEnableOption "development terminal emulator";

  config = lib.mkIf config.my.home.development.terminal.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "JetBrainsMono Nerd Font";
        size = 13;
      };
      settings = {
        scrollback_lines = 10000;
        enable_audio_bell = false;
        confirm_os_window_close = 0;
        background_opacity = "0.88";
        dynamic_background_opacity = true;
      };
    };
  };
}
