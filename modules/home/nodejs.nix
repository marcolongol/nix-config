{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.developer.enable {
  home.packages = [
    pkgs.nodejs_26
    pkgs.pnpm
    pkgs.yarn
    pkgs.npm-check-updates
  ];

  persistentFolders = [
    ".local/share/pnpm"
    ".npm"
  ];
}
