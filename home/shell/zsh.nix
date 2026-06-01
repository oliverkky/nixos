{ config, lib, ... }:

{
  options.my.home.shell.zsh.enable = lib.mkEnableOption "Zsh user configuration";

  config = lib.mkIf config.my.home.shell.zsh.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        ll = "ls -l";
        la = "ls -la";
        ls = "eza --icons";
        tree = "eza --tree --icons";
        update = "sudo nixos-rebuild switch --flake /etc/nixos#laptop1";
        nixcfg = "cd /etc/nixos";
        dotcfg = "cd /etc/nixos/dotfiles";
        nixedit = "cd /etc/nixos && $EDITOR .";
      };

      initContent = ''
        export PATH="$PATH:$HOME/.local/bin"
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "fzf"
        ];
        theme = "robbyrussell";
      };

      dotDir = config.home.homeDirectory;
    };

    # Starship prompt can replace the oh-my-zsh theme later.
    # programs.starship = {
    #   enable = true;
    #   settings = {
    #     add_newline = false;
    #     line_break.disabled = true;
    #     aws.disabled = true;
    #     gcloud.disabled = true;
    #   };
    # };
  };
}
