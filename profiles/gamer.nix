{
  config,
  lib,
  pkgs,
  osConfig,
  secretsPath,
  ...
}:
lib.mkIf (lib.elem "gamer" config.profiles) {
  home.packages = with pkgs; [
    discord
  ];

  persistentFolders = [
    ".config/Discord"
  ];
}
