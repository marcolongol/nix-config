{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "desktop-user" config.profiles) {
  home.packages = with pkgs; [
    alacritty
    glib
    nautilus
    thunderbird
    wl-clipboard
    filezilla
    pavucontrol
    solaar
  ];

  # ----------------
  # SECTION: Themes
  # ----------------

  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = "WhiteSur-dark";
    };
  };

  # ----------------
  # SECTION: Scripts
  # ----------------
  home.sessionPath = ["$HOME/.local/bin"];

  home.file.".local/bin/" = {
    source = ./scripts;
    recursive = true;
    executable = true;
  };

  # ---------------
  # SECTION: Rofi
  # ---------------
  programs.rofi = {
    enable = true;
  };

  # ---------------
  # SECTION: Waybar
  # ---------------
  stylix.targets.waybar = {
    addCss = false;
  };

  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
    };
    style = builtins.readFile ./waybar/style.css;
  };

  home.file.".config/waybar/config.jsonc".source = ./waybar/config.jsonc;
  home.file.".config/waybar/modules.jsonc".source = ./waybar/modules.jsonc;

  # ---------------
  # SECTION: Zen Browser
  # ---------------
  programs.zen-browser = {
    enable = true;
    profiles = {
      default = {
      };
    };
    nativeMessagingHosts = [pkgs.firefoxpwa];
    policies = let
      mkExtensionSettings = builtins.mapAttrs (_: pluginId: {
        install_url = "https://addons.mozilla.org/firefox/downloads/latest/${pluginId}/latest.xpi";
        installation_mode = "force_installed";
      });
    in {
      ExtensionSettings = mkExtensionSettings {
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = "vimium";
      };
    };
  };

  stylix.targets.zen-browser.profileNames = ["default"];

  # -----------------
  # SECTION: Hyprpaper
  # -----------------
  services.hyprpaper = {
    settings = {
      splash = false;
    };
  };

  # -----------------
  # SECTION: Hyprland
  # -----------------
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "alacritty";
      "$filemanager" = "nautilus";
      "$browser" = "zen-beta";
      "$menu" = "rofi -show drun -show-icons";
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        # col.active_border =
        # col.inactive_border =
        resize_on_border = true;
        allow_tearing = false;
        layout = "master";
      };
      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
      };
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 0.8;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          # color =
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };
      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, F, exec, $browser"
        "$mod, E, exec, $filemanager"
        "$mod, C, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, space, exec, $menu"

        "$mod, h, movefocus, l"
        "$mod, j, movefocus, d"
        "$mod, k, movefocus, u"
        "$mod, l, movefocus, r"

        "$mod CTRL, h, resizeactive, -20 0"
        "$mod CTRL, j, resizeactive, 0 20"
        "$mod CTRL, k, resizeactive, 0 -20"
        "$mod CTRL, l, resizeactive, 20 0"

        "$mod SHIFT, h, movewindow, l"
        "$mod SHIFT, j, movewindow, d"
        "$mod SHIFT, k, movewindow, u"
        "$mod SHIFT, l, movewindow, r"

        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        "$mod SHIFT, W, exec, wallctl.py next"
        "$mod, P, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"
      ];
      bindel = [
        ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        ",XF86AudioLowerVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%-"
        ",XF86AudioMute, exec, wpctl set-mute -l 1 @DEFAULT_AUDIO_SINK@ toggle"
        ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
      ];
    };
  };

  # -----------------
  # SECTION: Cliphist
  # -----------------
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # -----------------
  # SECTION: Hypridle
  # -----------------
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };
      listener = [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  # -----------------
  # SECTION: Persistence
  # -----------------
  persistentFolders = [
    ".thunderbird"
    ".config/zen"
    ".local/state/wireplumber"
  ];
}
