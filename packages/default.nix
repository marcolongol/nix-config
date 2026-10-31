{
  flake,
  pkgs,
  ...
}: {
  packages =
    builtins.removeAttrs
    (flake.inputs.omninix.lib.omninix.forAllNixFiles ./. (path: pkgs.callPackage path {}))
    ["default"]
    // {
      livecd-iso = flake.self.nixosConfigurations.nixos-livecd.config.system.build.isoImage;
    };
}
