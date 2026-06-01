{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.shell.enable = lib.mkEnableOption "system shell defaults";

  config = lib.mkIf config.my.nixos.shell.enable {
    # Zsh is configured here at the system level only for the minimum needed
    # to make it a valid login shell. The rest of the Zsh config lives in
    # Home Manager, where it belongs!

    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    environment.systemPackages = with pkgs; [
      vim # fallback editor
    ];
  };
}
