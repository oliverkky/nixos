{
  description = "Oliver's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    silentSDDM = {
      url = "github:uiriansan/SilentSDDM";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = lib.genAttrs supportedSystems;
      loadHost =
        name:
        let
          host =
            (lib.evalModules {
              modules = [
                ./hosts/schema.nix
                { config = import (./hosts + "/${name}/constants.nix"); }
              ];
            }).config;
        in
        assert lib.assertMsg (
          host.hostName == name
        ) "Host constants for ${name} set hostName to ${host.hostName}.";
        assert lib.assertMsg (lib.any (
          monitor: monitor.output == host.primaryMonitor
        ) host.monitors) "Host ${name} primaryMonitor ${host.primaryMonitor} is not present in monitors.";
        assert lib.assertMsg (
          host.secondaryMonitor == null
          || lib.any (monitor: monitor.output == host.secondaryMonitor) host.monitors
        ) "Host ${name} secondaryMonitor ${host.secondaryMonitor} is not present in monitors.";
        assert lib.assertMsg (
          (host.secondaryMonitor == null) == (host.secondaryMonitorWorkspace == null)
        ) "Host ${name} must set secondaryMonitor and secondaryMonitorWorkspace together.";
        host;
      laptop1 = loadHost "laptop1";
      workstation = loadHost "workstation";
      mkHost =
        name: host:
        lib.nixosSystem {
          system = host.system;
          specialArgs = {
            inherit inputs host;
          };
          modules = [
            (./hosts + "/${name}/configuration.nix")
            ./nixosModules
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${host.primaryUser} = import ./home/host-default.nix;
              home-manager.extraSpecialArgs = {
                inherit inputs host;
              };
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
    in
    {
      formatter = forAllSystems (
        system:
        nixpkgs.legacyPackages.${system}.writeShellApplication {
          name = "nix-fmt";
          runtimeInputs = [
            nixpkgs.legacyPackages.${system}.findutils
            nixpkgs.legacyPackages.${system}.nixfmt
          ];
          text = ''
            find . -path ./.git -prune -o -name '*.nix' -type f -exec nixfmt {} +
          '';
        }
      );

      nixosConfigurations.laptop1 = mkHost "laptop1" laptop1;
      nixosConfigurations.workstation = mkHost "workstation" workstation;
    };
}
