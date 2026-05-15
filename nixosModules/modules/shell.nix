{ config, pkgs, ... }:

{
  # Zsh is configured here at the system level only for the minimum needed
  # to make it a valid login shell. The rest of the Zsh config (aliases,
  # plugins, prompt) lives in home/modules/shell.nix via home-manager,
  # where it belongs (it's user-level state, not system-level policy).

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    vim # fallback editor, always useful on a live system
  ];
}
