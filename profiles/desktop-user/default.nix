{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./themes.nix
    ./hyprland.nix
    ./waybar.nix
    ./browser.nix
    ./lock.nix
    ./clipboard.nix
  ];

  options.profiles.desktopUser.enable = lib.mkEnableOption "desktop user profile (Hyprland, Waybar, Zen Browser)";

  # Packages, scripts, and persistence for the desktop-user profile.
  # Each sub-file guards itself with lib.mkIf config.profiles.desktopUser.enable.
  config = lib.mkIf config.profiles.desktopUser.enable {
    home.packages = with pkgs; [
      file-roller
      filezilla
      glib
      grim
      nautilus
      pavucontrol
      slurp
      solaar
      thunderbird
      vlc
      wl-clipboard
    ];

    home.sessionPath = ["$HOME/.local/bin"];

    home.file.".local/bin/" = {
      source = ./scripts;
      recursive = true;
      executable = true;
    };

    programs.rofi.enable = true;

    xdg.enable = lib.mkDefault true;

    persistentFolders = [
      ".thunderbird"
      ".local/state/wireplumber"
    ];
  };
}
