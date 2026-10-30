{
  config,
  lib,
  pkgs,
  ...
}: {
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = "WhiteSur-dark";
    };
  };
}
