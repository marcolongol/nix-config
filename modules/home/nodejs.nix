{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.developer.enable {
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
}
