{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  # Let our glass theme own the look. Stylix would otherwise inject its own
  # colors and clobber the rasi accents.
  stylix.targets.rofi.enable = false;

  programs.rofi = {
    enable = true;
    plugins = with pkgs; [
      rofi-emoji
      rofi-calc
    ];
    theme = ./rofi/glass.rasi;
    extraConfig = {
      modi = "drun,run,window,emoji,calc";
      show-icons = true;
      drun-display-format = "{name}";
      window-format = "{w}  {c}  {t}";
      kb-cancel = "Escape";
    };
  };
}
