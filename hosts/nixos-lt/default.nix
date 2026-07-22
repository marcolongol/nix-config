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
    laptop.enable = true;
    desktop.enable = true;
    nfsClient.enable = true;
    impermanent.enable = true;
    gaming.enable = true;
    docker.enable = true;
  };

  # Cloudflare tunnel for ad-hoc demo hosting. Setup (do once):
  #   1. `nix shell nixpkgs#cloudflared`
  #   2. `cloudflared tunnel login` -> browser auth
  #   3. `cloudflared tunnel create nixos-lt` -> copy UUID into tunnelId
  #   4. `sops secrets/nixos-lt.yaml` -> add key `cloudflared-credentials`
  #      with the full JSON content of `~/.cloudflared/<UUID>.json`
  #   5. In Cloudflare DNS: CNAME `*.nixos-lt` -> `<UUID>.cfargotunnel.com`
  #   6. Flip `enable = true` below and add apps.
  services.cloudflare-tunnel = {
    enable = true;
    tunnelId = "93fec6bb-b9db-43d3-a290-953d830d1ace";
    domain = "nixos-lt.marcolongo.dev";
    whoami.enable = false;
    apps = {
      demo = 4200;
    };
  };

  hostUsers = {
    lucas.enable = true;
  };

  # Networked printer at coworking space (driverless / IPP Everywhere).
  hardware.printers = {
    ensurePrinters = [
      {
        name = "Epson_ET4950";
        location = "EpsonSpot";
        deviceUri = "ipp://EPSONSPOT.local/ipp/print";
        model = "everywhere";
      }
    ];
    ensureDefaultPrinter = "Epson_ET4950";
  };

  # Monitor layout and workspace bindings
  # eDP-1: Chimei Innolux 1920x1080, built-in display, max refresh 144Hz, primary
  # DP-2: Samsung SMS27A350H 1920x1080, secondary via HP USB-C dock, positioned to the left at 60Hz (panel max)
  # Workspaces 1-5 on eDP-1 (primary), 6-10 on DP-2 (secondary)
  home-manager.users = lib.genAttrs activeUsers (_: {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        "DP-2,1920x1080@60,0x0,1"
        "eDP-1,1920x1080@144,1920x0,1"
      ];
      workspace = [
        "1, monitor:eDP-1"
        "2, monitor:eDP-1"
        "3, monitor:eDP-1"
        "4, monitor:eDP-1"
        "5, monitor:eDP-1"
        "6, monitor:DP-2"
        "7, monitor:DP-2"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
        "10, monitor:DP-2"
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
