inputs: final: _: {
  # Create NixOS configurations for a set of hosts discovered via mkDirMap.
  # Automatically applies overlays, injects specialArgs, and includes standard modules.
  mkNixosConfigurations = {
    hosts,
    system ? "x86_64-linux",
    roles ? {},
    users ? {},
    profiles ? {},
    homeManagerModules ? {},
    nixosModules ? {},
    extraModules ? [],
    specialArgs ? {},
  }:
    final.mapAttrs (
      hostName: hostPath:
        final.nixosSystem {
          inherit system;
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [
              (import ../overlays final)
            ];
          };
          specialArgs =
            {
              inherit inputs hostName users profiles homeManagerModules;
              secretsPath = ../secrets;
            }
            // specialArgs;
          modules =
            [
              hostPath
              inputs.home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              inputs.impermanence.nixosModules.impermanence
              inputs.stylix.nixosModules.stylix
              inputs.sops-nix.nixosModules.sops
              inputs.comin.nixosModules.comin
            ]
            ++ (final.attrValues nixosModules)
            ++ (final.attrValues roles)
            ++ extraModules;
        }
    )
    hosts;
}
