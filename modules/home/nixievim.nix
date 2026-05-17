{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.programs.nixievim = {
    enable = lib.mkEnableOption "nixievim";
    neovide.enable = lib.mkEnableOption "nixievim neovide support";
  };

  config = lib.mkMerge [
    (lib.mkIf config.programs.nixievim.enable {
      # NOTE:
      # Uncomment the following line and the
      # (inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.default.extend)
      # to enable stylix targets for nixvim.
      # This will export the stylix module to be used in the nixvim configuration.
      # ----
      # stylix.targets.nixvim.enable = false;

      home.packages = [
        pkgs.gcc
        pkgs.ripgrep
        pkgs.fd
        inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.default
        # (inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.default.extend
        #   config.stylix.targets.nixvim.exportedModule)
      ];
    })

    (lib.mkIf config.programs.nixievim.neovide.enable {
      home.packages = [
        inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.neovide
      ];
    })
  ];
}