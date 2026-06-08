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
      pkgs.playerctl
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

    programs.surfshark.enable = true;

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
      # colord answers CUPS' color-management D-Bus calls. Without it,
      # cupsd spews "CreateProfile failed: ServiceUnknown" at boot.
      colord.enable = lib.mkDefault true;
      blueman = {
        enable = lib.mkDefault true;
        # NixOS-generated drop-in collides with upstream blueman-applet.service
        # ExecStart=; use home-manager services.blueman-applet instead.
        withApplet = false;
      };
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
      # gtk portal serves org.freedesktop.portal.Settings (appearance, fonts,
      # color-scheme). Hyprland portal alone leaves that interface absent,
      # which breaks waybar's dark-mode detection and GTK app theming.
      extraPortals = [
        pkgs.xdg-desktop-portal-hyprland
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common = {
        default = ["hyprland" "gtk"];
        "org.freedesktop.impl.portal.Settings" = ["gtk"];
      };
    };

    # Long-running MPRIS dispatcher. Waybar's mpris module polls a player
    # name on D-Bus; without playerctld answering, every poll logs
    # "Unable to replace properties on 0". With it active, the module is
    # quiet and seamlessly switches between players (spotify, mpv, browser).
    systemd.user.services.playerctld = {
      description = "MPRIS dispatcher daemon (playerctld)";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.playerctl}/bin/playerctld daemon";
        Restart = "on-failure";
      };
    };

    security.rtkit.enable = true;
    hardware.graphics.enable = true;
    hardware.keyboard.zsa.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    stylix = {
      enable = true;
      image = pkgs.fetchurl {
        url = "https://w.wallhaven.cc/full/96/wallhaven-96gkyx.jpg";
        hash = "sha256-BK0u8EJcy5pd9KF891joEqcIWixWid8Ce+GZoL1HSko=";
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
