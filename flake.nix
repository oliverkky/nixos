{
  description = "Oliver's NixOS configuration";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-brave-origin.url = "github:NixOS/nixpkgs/pull/513143/head";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    codex-cli-nix.url = "github:sadjow/codex-cli-nix";
    hyprland = {
      url = "github:hyprwm/Hyprland";
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
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      laptop1 = import ./hosts/laptop1/constants.nix;
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

      nixosConfigurations.laptop1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
          host = laptop1;
        };
        modules = [
          ./hosts/laptop1/configuration.nix
          ./nixosModules
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${laptop1.primaryUser} = import ./hosts/laptop1/home.nix;
            home-manager.extraSpecialArgs = {
              inherit inputs;
              host = laptop1;
            };
            home-manager.backupFileExtension = "backup";
          }
        ];
      };
    };
}
