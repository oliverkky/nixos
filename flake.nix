{
  description = "Oliver's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
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
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      laptop1 = import ./hosts/laptop1/constants.nix;
      workstation = import ./hosts/workstation/constants.nix;
      mkHost =
        name: host:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
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
              home-manager.users.${host.primaryUser} = import (./hosts + "/${name}/home.nix");
              home-manager.extraSpecialArgs = {
                inherit inputs host;
              };
              home-manager.backupFileExtension = "backup";
            }
          ];
        };
    in
    {
      formatter.x86_64-linux = pkgs.writeShellApplication {
        name = "nix-fmt";
        runtimeInputs = [
          pkgs.findutils
          pkgs.nixfmt
        ];
        text = ''
          find . -path ./.git -prune -o -name '*.nix' -type f -exec nixfmt {} +
        '';
      };

      nixosConfigurations.laptop1 = mkHost "laptop1" laptop1;
      nixosConfigurations.workstation = mkHost "workstation" workstation;
    };
}
