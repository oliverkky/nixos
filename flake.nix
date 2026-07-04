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
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      validateHost =
        name: host:
        let
          requiredPaths = [
            [ "hostName" ]
            [ "primaryMonitor" ]
            [ "primaryUser" ]
            [ "primaryUid" ]
            [ "primaryGid" ]
            [ "stateVersion" ]
            [
              "cursor"
              "name"
            ]
            [
              "cursor"
              "size"
            ]
            [
              "cursor"
              "dpi"
            ]
            [ "monitors" ]
            [
              "reaper"
              "uiScale"
            ]
            [
              "reaper"
              "pipewireLatency"
            ]
            [
              "zed"
              "audioDevice"
            ]
          ];
          missingPaths = lib.filter (path: !(lib.hasAttrByPath path host)) requiredPaths;
          missing = lib.concatMapStringsSep ", " (lib.concatStringsSep ".") missingPaths;
        in
        assert lib.assertMsg (
          host.hostName == name
        ) "Host constants for ${name} set hostName to ${host.hostName}.";
        assert lib.assertMsg (missingPaths == [ ]) "Host ${name} is missing constants: ${missing}.";
        host;
      laptop1 = validateHost "laptop1" (import ./hosts/laptop1/constants.nix);
      workstation = validateHost "workstation" (import ./hosts/workstation/constants.nix);
      mkHost =
        name: host:
        lib.nixosSystem {
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
