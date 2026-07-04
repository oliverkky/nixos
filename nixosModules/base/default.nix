{
  host,
  pkgs,
  ...
}:

{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.${host.primaryUser} = {
    isNormalUser = true;
    description = host.primaryUserDescription or "Oliver Klinkovský";
    uid = host.primaryUid;
    group = "users";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;
  };
  users.groups.users.gid = host.primaryGid;

  time.timeZone = "Europe/Prague";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "cs_CZ.UTF-8";
    LC_IDENTIFICATION = "cs_CZ.UTF-8";
    LC_MEASUREMENT = "cs_CZ.UTF-8";
    LC_MONETARY = "cs_CZ.UTF-8";
    LC_NAME = "cs_CZ.UTF-8";
    LC_NUMERIC = "cs_CZ.UTF-8";
    LC_PAPER = "cs_CZ.UTF-8";
    LC_TELEPHONE = "cs_CZ.UTF-8";
    LC_TIME = "cs_CZ.UTF-8";
  };

  console.keyMap = "cz-lat2";

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  system.stateVersion = host.stateVersion;
}
