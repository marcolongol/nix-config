{inputs, ...}: let
  # Extend the Nixpkgs lib with my custom stuff
  lib = inputs.nixpkgs.lib.extend (
    final: _: {
      # Map an attribute set to a list, applying a function to each attribute
      mapAttrsMaybe = f: attrs:
        final.pipe attrs [
          (final.mapAttrsToList f)
          (builtins.filter (x: x != null))
          builtins.listToAttrs
        ];

      # Apply a function to all .nix files in a directory, returning an attribute set
      forAllNixFiles = dir: f:
        if builtins.pathExists dir
        then
          final.pipe dir [
            builtins.readDir
            (final.mapAttrsMaybe (
              fn: type:
                if type == "regular"
                then final.nameValuePair (final.removeSuffix ".nix" fn) (f "${dir}/${fn}")
                else if type == "directory" && builtins.pathExists "${dir}/${fn}/default.nix"
                then final.nameValuePair fn (f "${dir}/${fn}")
                else null
            ))
          ]
        else {};

      # Recursively apply a function to all .nix files in a directory tree
      mkDirMap = final.mapAttrs (_: dir: final.forAllNixFiles dir (fn: fn));

      # Create NixOS configurations for a set of hosts
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
                  (import ./overlays)
                ];
              };
              specialArgs =
                {
                  inherit inputs hostName users profiles homeManagerModules;
                  secretsPath = ./secrets;
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
                ++ (lib.attrValues nixosModules)
                ++ (lib.attrValues roles)
                ++ extraModules;
            }
        )
        hosts;
    }
  );
in
  lib
