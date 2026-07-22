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
    ./rofi.nix
    ./browser.nix
    ./lock.nix
    ./clipboard.nix
    ./notifications.nix
    ./wayvnc.nix
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
      playerctl
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

    services.blueman-applet.enable = true;

    # Long-running MPRIS dispatcher. Waybar's mpris module polls a player
    # name on D-Bus; without playerctld answering, every poll logs
    # "Unable to replace properties on 0". With it active, the module is
    # quiet and seamlessly switches between players (spotify, mpv, browser).
    services.playerctld.enable = true;

    # On-screen volume/brightness popup. Keys are bound to swayosd-client in
    # hyprland.nix; this runs the server. Brightness write perms come from the
    # swayosd udev rule enabled in roles/desktop.nix.
    services.swayosd.enable = true;

    persistentFolders = [
      ".thunderbird"
      ".local/state/wireplumber"
      # Harmony SASE (Perimeter81) keeps its session/auth (Cookies, Local
      # Storage) here; without this the wiped-root impermanence setup forces a
      # re-login on every boot. Travels with roles.desktop, which enables the
      # VPN agent. Both the legacy and rebranded config dir names are persisted.
      ".config/Perimeter81"
      ".config/Harmony SASE"
    ];
  };
}
