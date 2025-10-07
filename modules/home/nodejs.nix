{pkgs, ...}: let
  nodejs = pkgs.nodejs_latest;

  myNodePackages = pkgs.nodePackages.override {
    inherit nodejs;
  };
in {
  home.packages = [
    nodejs
    myNodePackages.typescript
    myNodePackages.eslint
    myNodePackages.prettier
    myNodePackages.npm-check-updates
    myNodePackages.yarn
    myNodePackages.pnpm
  ];
}
