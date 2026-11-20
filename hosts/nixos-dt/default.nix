{
  config,
  lib,
  ...
}: {
  system.stateVersion = "26.05";

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  roles = {
    common.enable = true;
    desktop.enable = true;
    nfsClient.enable = true;
    impermanent = {
      enable = true;
      persistCoredumps = true;
      wipe = {
        enable = true;
        acknowledgeDataLoss = true;
      };
    };
    gaming.enable = true;
    docker.enable = true;
  };

  omninix.hostUsers = {
    lucas = {
      enable = true;
      extraGroups = ["wheel" "networkmanager" "plugdev" "docker"];
    };
  };

  # DP-2: LG ULTRAGEAR 2560x1440, main monitor, max refresh (164.96Hz)
  # HDMI-A-1: Samsung U28H75x 4K, secondary, landscape, 30Hz max over HDMI (1.5 scale -> 2560x1440 logical)
  # Workspaces 1-5 on DP-2 (main), 6-10 on HDMI-A-1 (secondary)
  home-manager.users = lib.genAttrs config.omninix.activeUsers (_: {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        {
          output = "DP-2";
          mode = "2560x1440@164.96";
          position = "0x0";
          scale = 1;
          bitdepth = 10;
          cm = "hdr";
          sdrbrightness = 5;
          vrr = 2;
        }
        {
          output = "HDMI-A-1";
          mode = "3840x2160@30";
          position = "2560x0";
          scale = 1.5;
        }
      ];
      workspace_rule = map (i: {
        workspace = toString i;
        monitor =
          if i <= 5
          then "DP-2"
          else "HDMI-A-1";
      }) (lib.range 1 10);
    };
  });
}
