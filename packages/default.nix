{
  flake,
  pkgs,
  ...
}: {
  packages = {
    livecd-iso = flake.self.nixosConfigurations.nixos-livecd.config.system.build.isoImage;
    surfshark = pkgs.callPackage ./surfshark.nix { };
  };
}
