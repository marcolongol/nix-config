{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: {
  options.programs.nixievim.enable = lib.mkEnableOption "nixievim";

  config = lib.mkIf config.programs.nixievim.enable {
    home.packages = [
      pkgs.gcc
      pkgs.ripgrep
      pkgs.fd
      inputs.nixievim.packages.${pkgs.system}.default
    ];
  };
}
