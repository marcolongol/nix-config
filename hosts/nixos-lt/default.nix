{lib, ...}: let
  roles = ["common" "laptop" "desktop" "nfs-client" "impermanent" "gaming" "docker"];
  hostUsers = ["lucas"];
in {
  system.stateVersion = "25.11";

  inherit roles hostUsers;

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  # Monitor layout and workspace bindings
  # eDP-1: Chimei Innolux 1920x1080, built-in display, max refresh 144Hz
  home-manager.users = lib.genAttrs hostUsers (_: {
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
