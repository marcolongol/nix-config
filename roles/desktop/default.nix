# Hyprland desktop, themed by stylix. Needs stylix's NixOS module, and a
# wallpaper (stylix.image) set by the flake using it.
{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  sddm-astronaut = pkgs.sddm-astronaut.override {
    # embeddedTheme = "black_hole";
  };
in {
  options.roles.desktop.enable = lib.mkEnableOption "desktop environment (Hyprland, SDDM, Pipewire)";

  config = lib.mkIf config.roles.desktop.enable (lib.mkMerge [
    {
      omninix.requirements = [
        {
          by = "roles.desktop";
          option = "stylix.image";
          module = "stylix's NixOS module (inputs.stylix.nixosModules.stylix)";
        }
      ];

      # The home half themes through stylix too, so it only comes with it (a
      # missing stylix then reports the requirement above, not an HM option error).
      home-manager.sharedModules = lib.optional (options ? stylix.image) ./home;

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
        polkitPolicyOwners = config.omninix.activeUsers;
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

      # ensurePrinters queues are declared by hostname (ipp://NAME.local), so
      # lpadmin exits 1 whenever you are not on the LAN that printer lives on —
      # which fails the whole activation. Unreachable printer is the only
      # realistic failure here, so let exit 1 pass.
      systemd.services.ensure-printers.serviceConfig.SuccessExitStatus = [0 1];

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

      # Unlock the login keyring with the password typed at the SDDM greeter.
      # pam_ssh_agent_auth (yubikey touch) bypasses this, so keep typing your
      # password at the display manager for the keyring to auto-unlock.
      security.pam.services.sddm.enableGnomeKeyring = true;

      security.rtkit.enable = true;
      hardware.graphics.enable = true;
      hardware.keyboard.zsa.enable = true;
      hardware.logitech.wireless.enable = true;
      programs.solaar.enable = true; # was hardware.logitech.wireless.enableGraphical

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
    }

    (lib.optionalAttrs (options ? stylix.image) {
      stylix = {
        enable = true;
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
    })
  ]);
}
