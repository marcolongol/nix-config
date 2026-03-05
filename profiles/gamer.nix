{
  config,
  lib,
  pkgs,
  osConfig,
  secretsPath,
  ...
}:
lib.mkIf (lib.elem "gamer" config.profiles) {
  programs.mangohud = {
    enable = true;
    settings = {
      position = "top-left";
      toggle_hud = "Shift_R+F12";

      fps = true;
      frame_timing = 1;

      gpu_stats = true;
      gpu_temp = true;
      gpu_power = true;
      vram = true;

      cpu_stats = true;
      cpu_temp = true;
      ram = true;
    };
  };

  home.packages = with pkgs; [
    discord
  ];

  persistentFolders = [
    ".config/Discord"
  ];
}
