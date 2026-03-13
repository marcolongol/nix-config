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

  # Packages, scripts, and persistence for the desktop-user profile.
  # Each sub-file guards itself with lib.mkIf (lib.elem "desktop-user" config.profiles).
  config = lib.mkIf (lib.elem "desktop-user" config.profiles) {
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
