{
  config,
  lib,
  pkgs,
  ...
}: lib.mkIf config.profiles.developer.enable (let
  nodejs = pkgs.nodejs;

  myNodePackages = pkgs.nodePackages.override {
    inherit nodejs;
  };
in {
  home.packages = [
    nodejs
    pkgs.pnpm
    pkgs.yarn
    myNodePackages.typescript
    myNodePackages.eslint
    myNodePackages.prettier
    myNodePackages.npm-check-updates
  ];

  persistentFolders = [
    ".local/share/pnpm"
    ".npm"
  ];
})
