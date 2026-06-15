{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    # embeddedTheme = "black_hole";
  };
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);

  # Wallpaper rotation: deterministic pick from ./wallpapers/ based on flake
  # lastModified. Each comin sync produces a new timestamp -> new index ->
  # different wallpaper + theme. Pure-Nix friendly, no runtime daemon.
  wallpaperDir = inputs.self + "/wallpapers";
  wallpaperFiles = lib.pipe (builtins.readDir wallpaperDir) [
    (lib.filterAttrs (n: t:
      t
      == "regular"
      && builtins.any (ext: lib.hasSuffix ext (lib.toLower n)) [".jpg" ".jpeg" ".png" ".webp"]))
    lib.attrNames
    (builtins.sort builtins.lessThan)
  ];
  wallpaperIndex = lib.mod inputs.self.lastModified (builtins.length wallpaperFiles);
  selectedWallpaper = wallpaperDir + "/${builtins.elemAt wallpaperFiles wallpaperIndex}";
in {
  options.roles.desktop.enable = lib.mkEnableOption "desktop environment (Hyprland, SDDM, Pipewire)";

  config = lib.mkIf config.roles.desktop.enable {
    environment.systemPackages = [
      sddm-astronaut
      pkgs.bibata-cursors
      pkgs.playerctl
      pkgs.seahorse
    ];

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
      withUWSM = true;
    };

    programs.hyprlock.enable = true;

    # udev rule so swayosd-server (user session) can write /sys/class/backlight
    # for the brightness OSD without root.
    services.udev.packages = [pkgs.swayosd];

    programs._1password.enable = true;
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = activeUsers;
    };

    programs.surfshark.enable = true;
    programs.harmony-sase.enable = true;
    # TEMPORARY: same posture-check spoof as nixos-lt — macOS-only server-side
    # profile hits Linux too. Remove once the admin-console profile is corrected.
    programs.harmony-sase.spoofDpcFiles = ["/dev/null/MacOS_Prohibited_on_TEOCO_VPN"];

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
      # Secret Service daemon (org.freedesktop.secrets). Apps like Anytype
      # (via libsecret) persist their vault key here instead of prompting
      # every boot. The login keyring is unlocked by the SDDM password via
      # pam_gnome_keyring (enabled below). seahorse is the GUI to inspect it.
      gnome.gnome-keyring.enable = true;
      printing = {
        enable = lib.mkDefault true;
        # Auto-discover IPP/mDNS printers on the current LAN. Pairs with
        # hardware.printers.ensurePrinters: known printers get stable queue
        # names; unknown ones (hotels, coworking, etc.) appear automatically.
        browsed.enable = lib.mkDefault true;
      };
      # colord answers CUPS' color-management D-Bus calls. Without it,
      # cupsd spews "CreateProfile failed: ServiceUnknown" at boot.
      colord.enable = lib.mkDefault true;
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

    # Unlock the login keyring with the password typed at the SDDM greeter.
    # pam_ssh_agent_auth (yubikey touch) bypasses this, so keep typing your
    # password at the display manager for the keyring to auto-unlock.
    security.pam.services.sddm.enableGnomeKeyring = true;

    security.rtkit.enable = true;
    hardware.graphics.enable = true;
    hardware.keyboard.zsa.enable = true;
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    # MX Master 3: thumb gesture button (CID 0xc3) -> workspace switching.
    # Emits Super+Ctrl+Left/Right, bound in hyprland.nix.
    services.logiops = {
      enable = true;
      config = {
        devices = [
          {
            name = "Wireless Mouse MX Master 3";
            buttons = [
              {
                cid = 195; # 0xc3 gesture button
                action = {
                  type = "Gestures";
                  gestures = [
                    {
                      direction = "Right";
                      mode = "OnRelease";
                      action = {
                        type = "Keypress";
                        keys = ["KEY_LEFTMETA" "KEY_LEFTCTRL" "KEY_RIGHT"];
                      };
                    }
                    {
                      direction = "Left";
                      mode = "OnRelease";
                      action = {
                        type = "Keypress";
                        keys = ["KEY_LEFTMETA" "KEY_LEFTCTRL" "KEY_LEFT"];
                      };
                    }
                    {
                      direction = "None";
                      mode = "NoPress";
                    }
                  ];
                };
              }
            ];
          }
        ];
      };
    };

    stylix = {
      enable = true;
      image = selectedWallpaper;
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
