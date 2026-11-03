{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../modules/home/session-path.nix
    ./themes.nix
    ./hyprland.nix
    ./waybar.nix
    ./rofi.nix
    ./browser.nix
    ./lock.nix
    ./clipboard.nix
    ./notifications.nix
    ./chromium.nix
  ];

  # Home side of roles.desktop, applied to every user via home-manager.sharedModules.
  config = {
    # $terminal in hyprland.nix.
    programs.ghostty.enable = lib.mkDefault true;

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

    home.sessionPathAppend = ["$HOME/.local/bin"];

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
    # swayosd udev rule enabled in roles/desktop/default.nix.
    services.swayosd.enable = true;

    # Automount removable drives, with tray icon and notifications.
    services.udiskie.enable = true;

    omninix.persistence.directories = [
      ".thunderbird"
      # gnome-keyring: app secrets and Chromium's cookie/password key
      ".local/share/keyrings"
      ".local/state/wireplumber"
    ];
  };
}
