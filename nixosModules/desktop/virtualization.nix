{
  config,
  host,
  lib,
  pkgs,
  ...
}:

{
  options.my.nixos.desktop.virtualization.enable =
    lib.mkEnableOption "desktop virtual machine management with KVM/QEMU";

  config = lib.mkIf config.my.nixos.desktop.virtualization.enable {
    virtualisation.libvirtd = {
      enable = true;
      qemu.swtpm.enable = true;
    };

    programs.virt-manager.enable = true;

    systemd.services.libvirt-default-network = {
      description = "Start the default libvirt NAT network";
      wantedBy = [ "multi-user.target" ];
      after = [ "libvirtd.service" ];
      requires = [ "libvirtd.service" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        ${pkgs.libvirt}/bin/virsh net-start default || \
          ${pkgs.libvirt}/bin/virsh net-info default | ${pkgs.gnugrep}/bin/grep -q '^Active:.*yes'
      '';
    };

    users.users.${host.primaryUser}.extraGroups = [
      "kvm"
      "libvirtd"
    ];

    environment.systemPackages = with pkgs; [
      gnome-boxes
      spice-gtk
      virt-viewer
    ];
  };
}
