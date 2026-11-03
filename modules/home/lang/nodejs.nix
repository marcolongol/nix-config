{
  config,
  lib,
  pkgs,
  ...
}: {
  options.lang.nodejs.enable = lib.mkEnableOption "Node.js toolchain";

  config = lib.mkIf config.lang.nodejs.enable {
    home.packages = [
      pkgs.nodejs
      pkgs.pnpm
      pkgs.yarn
      pkgs.npm-check-updates
    ];

    omninix.persistence.directories = [
      ".local/share/pnpm"
      ".npm"
    ];
  };
}
