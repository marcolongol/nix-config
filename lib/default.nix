{inputs, ...}: let
  # Extend the Nixpkgs lib with custom utilities, split across focused sub-files
  lib = inputs.nixpkgs.lib.extend (
    final: prev:
      (import ./mkDirMap.nix final prev)
      // (import ./mkNixosConfigurations.nix inputs final prev)
  );
in
  lib
