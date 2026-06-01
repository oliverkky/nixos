{ config, lib, ... }:

{
  options.my.home.development.git.enable = lib.mkEnableOption "Git user configuration";

  config = lib.mkIf config.my.home.development.git.enable {
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "OliverKKY";
          email = "oklink@seznam.cz";
        };
        init.defaultBranch = "main";
        pull.rebase = true;
        push.autoSetupRemote = true;
        core.editor = "nvim";
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
  };
}
