{
  config,
  lib,
  ...
}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  system.stateVersion = "25.11";

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  roles = {
    common.enable = true;
    desktop.enable = true;
    nfsClient.enable = true;
    impermanent.enable = true;
    gaming.enable = true;
    docker.enable = true;
  };

  hostUsers = {
    lucas.enable = true;
  };

  # Monitor layout and workspace bindings are host-specific so they live here rather than in the desktop-user profile.
  # DP-2: LG ULTRAGEAR 2560x1440, main monitor, max refresh (164.96Hz)
  # HDMI-A-1: Samsung U28H75x 4K, secondary, reversed portrait (transform=3), 30Hz max over HDMI
  # Workspaces 1-5 on DP-2 (main), 6-10 on HDMI-A-1 (secondary)
  home-manager.users = lib.genAttrs activeUsers (_: {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        "DP-2,2560x1440@164.96,0x0,1"
        "HDMI-A-1,3840x2160@30,2560x0,1.5,transform,3"
      ];
      workspace = [
        "1, monitor:DP-2"
        "2, monitor:DP-2"
        "3, monitor:DP-2"
        "4, monitor:DP-2"
        "5, monitor:DP-2"
        "6, monitor:HDMI-A-1, layoutopt:orientation:top"
        "7, monitor:HDMI-A-1, layoutopt:orientation:top"
        "8, monitor:HDMI-A-1, layoutopt:orientation:top"
        "9, monitor:HDMI-A-1, layoutopt:orientation:top"
        "10, monitor:HDMI-A-1, layoutopt:orientation:top"
      ];
    };
  });
}
