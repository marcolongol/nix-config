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
        overlays = import ../../overlays;
      };
    };

    formatter = pkgs.alejandra;

    imports = [
      (self + /packages)
    ];
  };

  flake = inputs.omninix.lib.omninix.mkFlake inputs {
    hostsDir = ../../hosts;
    rolesDir = ../../roles;
    usersDir = ../../users;
    profilesDir = ../../profiles;
    nixosModulesDir = ../../modules/nixos;
    homeManagerModulesDir = ../../modules/home;
    overlaysDir = ../../overlays;
    secretsPath = ../../secrets;
    allowUnfree = true;
  };
}
