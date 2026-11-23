{
  config,
  lib,
  ...
}: {
  stylix.targets.waybar = {
    addCss = false;
  };

  programs.waybar = {
    enable = true;
    systemd.enable = true;
    style = builtins.readFile ./style.css;
  };

  home.file.".config/waybar/config.jsonc".source = ./config.jsonc;
  home.file.".config/waybar/modules.jsonc".source = ./modules.jsonc;
}
