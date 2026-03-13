{
  config,
  lib,
  ...
}:
lib.mkIf (lib.elem "desktop-user" config.profiles) {
  stylix.targets.waybar = {
    addCss = false;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = builtins.readFile ./waybar/style.css;
  };

  home.file.".config/waybar/config.jsonc".source = ./waybar/config.jsonc;
  home.file.".config/waybar/modules.jsonc".source = ./waybar/modules.jsonc;
}