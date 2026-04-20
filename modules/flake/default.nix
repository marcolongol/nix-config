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
        overlays = let
          lib = import ../../lib {inherit inputs;};
        in [
          (import ../../overlays lib)
        ];
      };
    };

    formatter = pkgs.alejandra;

    imports = [
      (self + /packages)
    ];
  };

  flake = let
    lib = import ../../lib {inherit inputs;};
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
