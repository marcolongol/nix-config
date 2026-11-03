{
  config,
  lib,
  pkgs,
  ...
}: {
  options.lang.nix.enable = lib.mkEnableOption "Nix tooling (formatter, LSP, linters, nh)";

  config = lib.mkIf config.lang.nix.enable {
    home.packages = with pkgs; [
      alejandra
      nixd
      deadnix
      statix
      nh
    ];
  };
}
