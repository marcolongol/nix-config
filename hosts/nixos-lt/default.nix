{config, lib, ...}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  system.stateVersion = "25.11";

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  roles = {
    common.enable = true;
    laptop.enable = true;
    desktop.enable = true;
    nfsClient.enable = true;
    impermanent.enable = true;
    gaming.enable = true;
    docker.enable = true;
  };

  hostUsers = {
    lucas.enable = true;
  };

  # Monitor layout and workspace bindings
  # eDP-1: Chimei Innolux 1920x1080, built-in display, max refresh 144Hz
  home-manager.users = lib.genAttrs activeUsers (_: {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
      ];
    };
  });

  # secrets
  sops = {
    secrets = {
      host-secret = {
        owner = "lucas";
        mode = "0400";
      };
    };
  };
}
