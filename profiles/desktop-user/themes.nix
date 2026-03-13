{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "desktop-user" config.profiles) {
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = "WhiteSur-dark";
    };
  };
}
