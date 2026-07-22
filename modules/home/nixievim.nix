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
      home.packages = [
        pkgs.gcc
        pkgs.ripgrep
        pkgs.fd
        inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    })

    (lib.mkIf config.programs.nixievim.neovide.enable {
      home.packages = [
        inputs.nixievim.packages.${pkgs.stdenv.hostPlatform.system}.neovide
      ];
    })
  ];
}