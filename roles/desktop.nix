{
  config,
  lib,
  pkgs,
  ...
}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    # embeddedTheme = "black_hole";
  };
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  options.roles.desktop.enable = lib.mkEnableOption "desktop environment (Hyprland, SDDM, Pipewire)";

  config = lib.mkIf config.roles.desktop.enable {
    environment.systemPackages = [
      sddm-astronaut
      pkgs.bibata-cursors
    ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    programs.hyprlock.enable = true;

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = activeUsers;
    };

    environment.etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          .zen-wrapped
          zen
        '';
        mode = "0755";
      };
    };

    services = {
      printing.enable = lib.mkDefault true;
      blueman.enable = lib.mkDefault true;
      hypridle.enable = lib.mkDefault true;
      pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };
      displayManager = {
        defaultSession = "hyprland-uwsm";
        sddm = {
          enable = true;
          wayland = {
            enable = true;
            compositor = "kwin";
          };
          package = pkgs.kdePackages.sddm;
          theme = "sddm-astronaut-theme";
          extraPackages = [sddm-astronaut];
          settings = {
            Theme = {
              CursorTheme = "Bibata-Modern-Ice";
              CursorSize = 24;
            };
          };
        };
      };
    };

    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-hyprland];
      config.common.default = "*";
    };

    security.rtkit.enable = true;
    hardware.graphics.enable = true;
    hardware.keyboard.zsa.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    stylix = {
      enable = true;
      image = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/3q/wallhaven-3q3z9d.jpg";
        hash = "sha256-VsbazfMLpq2z9LmNZRBWJtPEWbwBZ/7w1ZBhaCMR+m0=";
      };
      autoEnable = true;
      polarity = "dark";
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.meslo-lg;
          name = "MesloLGS Nerd Font";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        sizes = {
          applications = 12;
          terminal = 9;
          desktop = 10;
          popups = 10;
        };
      };
    };
  };
}