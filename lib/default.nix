{inputs, ...}: let
  lib = inputs.nixpkgs.lib.extend (
    final: prev:
      (import ./mkDirMap.nix final prev)
      // (import ./mkNixosConfigurations.nix inputs final prev)
  );
in
  lib
