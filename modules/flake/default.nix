{
  self,
  inputs,
  ...
}: {
  perSystem = {
    system,
    pkgs,
    ...
  }: {
    _module.args = {
      flake = {inherit inputs self;};
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (import ../../overlays)
        ];
      };
    };

    formatter = pkgs.alejandra;

    imports = [
    ];
  };

  flake = let
    lib = import ../../lib.nix {inherit inputs lib;};
    dirs = lib.mkDirMap {
      hosts = ../../hosts;
      roles = ../../roles;
      users = ../../users;
      profiles = ../../profiles;
      nixosModules = ../../modules/nixos;
      homeManagerModules = ../../modules/home;
    };
  in
    {
      inherit lib;
      nixosConfigurations = lib.mkNixosConfigurations {
        inherit (dirs) hosts roles nixosModules users profiles homeManagerModules;
      };
    }
    // dirs;
}
