{
  flake,
  pkgs,
  ...
}: {
  packages =
    builtins.removeAttrs
    (flake.self.lib.forAllNixFiles ./. (path: pkgs.callPackage path {}))
    ["default"]
    // {
      livecd-iso = flake.self.nixosConfigurations.nixos-livecd.config.system.build.isoImage;
    };
}
