{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  gtk = {
    enable = true;
    gtk4.theme = null;
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = "WhiteSur-dark";
    };
  };
}
