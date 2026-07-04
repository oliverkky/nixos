{
  host,
  ...
}:

{
  imports = [
    ./edid.nix
    ./hardware-configuration.nix
  ];

  my.nixos = {
    desktop = {
      enable = true;
      audio.production.enable = true;
    };
    development.enable = true;
    laptop.enable = true;
    networking = {
      enable = true;
      hostName = host.hostName;
    };
    shell.enable = true;
  };

  # ── Laptop power behavior ───────────────────────────────────────────────────

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

}
