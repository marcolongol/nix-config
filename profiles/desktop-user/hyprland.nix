{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  services.hyprpaper = {
    settings = {
      splash = false;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
      # ponytail: hyprspace can't build against hyprland 0.56 (removed managers/animation/AnimationManager.hpp);
      # upstream unfixed as of 2026-05-28. Re-add when it supports 0.56, and restore $mod+Tab + plugin.overview below.
      # pkgs.hyprlandPlugins.hyprspace
    ];
    settings = {
      "$mod" = "SUPER";
      "$terminal" = "ghostty";
      "$filemanager" = "nautilus";
      "$browser" = "zen-beta";
      "$menu" = "rofi -show drun -show-icons";
      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 2;
        resize_on_border = true;
        allow_tearing = false;
        layout = "master";
      };
      misc = {
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
      };
      animations = {
        enabled = true;
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
        ];
        animation = [
          "windows, 1, 4, easeOutQuint"
          "windowsIn, 1, 4, easeOutQuint, popin 87%"
          "windowsOut, 1, 3, easeOutQuint, popin 87%"
          "border, 1, 6, linear"
          "fade, 1, 4, easeInOutCubic"
          "workspaces, 1, 5, easeOutQuint, slide"
          "specialWorkspace, 1, 5, easeOutQuint, slidevert"
        ];
      };
      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
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
        # ponytail: needs hyprspace, disabled for hyprland 0.56 — restore with plugin above
        # "$mod, Tab, exec, hyprctl dispatch overview:toggle"

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
        "$mod, D, togglespecialworkspace, minimized"
        "$mod SHIFT, S, movetoworkspace, special:magic"

        "$mod, P, exec, cliphist list | rofi -dmenu | cliphist decode | wl-copy"

        "$mod, N, exec, swaync-client -t -sw"

        # Rofi launchers
        "$mod, X, exec, rofi-power.sh"
        "$mod, W, exec, rofi-wifi.sh"
        "$mod, B, exec, rofi-bluetooth.sh"
        "$mod, semicolon, exec, rofi -show emoji"
        "$mod, equal, exec, rofi -show calc -no-show-match -no-sort"
        "$mod SHIFT, Tab, exec, rofi -show window"

        "CTRL ALT, S, exec, grim -g \"$(slurp)\" - | wl-copy"

        # Workspace prev/next (also emitted by MX Master gesture button via logiops)
        "$mod CTRL, right, workspace, e+1"
        "$mod CTRL, left, workspace, e-1"

        "$mod, comma, focusmonitor, -1"
        "$mod, period, focusmonitor, +1"
        "$mod SHIFT, comma, movewindow, mon:-1"
        "$mod SHIFT, period, movewindow, mon:+1"
      ];
      plugin = {
        # ponytail: hyprspace disabled for hyprland 0.56 — restore with plugin above
        # overview = {
        #   centerAligned = true;
        #   hideBackgroundLayers = false;
        #   exitOnClick = true;
        #   exitOnSwitch = true;
        #   autoDrag = true;
        #   gapsIn = 5;
        #   gapsOut = 20;
        #   bgCol = "rgb(1e1e2e)";
        # };
        hyprbars = {
          bar_height = 28;
          bar_color = "rgb(1e1e2e)";
          "col.text" = "rgb(cdd6f4)";
          bar_text_size = 11;
          bar_part_of_window = true;
          bar_precedence_over_border = true;
          # buttons render right-to-left
          "hyprbars-button" = [
            "rgb(f38ba8), 13, , hyprctl dispatch killactive"
            "rgb(f9e2af), 13, , hyprctl dispatch fullscreen 1"
            "rgb(a6e3a1), 13, , hyprctl dispatch movetoworkspacesilent special:minimized"
          ];
        };
      };
      bindel = [
        ",XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
        ",XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
        ",XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
        ",XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
        ",XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
        ",XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
      ];
    };
    # Window rules use Hyprland 0.53+ syntax: `windowrule` is a special
    # category keyed by `name` (must be the first field) with `match:*`
    # selectors and rule fields. The old flat `windowrulev2 = "float, class:..."`
    # form is gone in 0.55 (prints a deprecation error + red popup). Emitted as
    # raw text because the name-first ordering can't survive Nix attr sorting.
    extraConfig = ''
      windowrule {
        name = float-center-pavucontrol
        match:class = ^(org.pulseaudio.pavucontrol)$
        float = true
        center = true
      }
      windowrule {
        name = float-center-blueman
        match:class = ^(\.blueman-manager-wrapped)$
        float = true
        center = true
      }
      windowrule {
        name = nautilus-opacity
        match:class = ^(org.gnome.Nautilus)$
        opacity = 0.90 0.82
      }
      windowrule {
        name = float-nautilus-props
        match:class = ^(org.gnome.Nautilus)$
        match:title = ^(.*Properties.*)$
        float = true
      }
      windowrule {
        name = float-center-1password
        match:class = ^(1password)$
        float = true
        center = true
      }
      windowrule {
        name = pip
        match:title = ^(Picture-in-Picture)$
        float = true
        pin = true
        keep_aspect_ratio = true
      }
      windowrule {
        name = idleinhibit-fullscreen
        match:class = ^(.*)$
        idle_inhibit = fullscreen
      }

      # Frost the swaync control center: its CSS background is translucent,
      # this blurs the desktop behind it. ignore_alpha keeps fully-transparent
      # regions (gaps between cards) from rendering a blur rectangle.
      # layerrule is a special category (same 0.53+ syntax as windowrule).
      layerrule {
        name = blur-swaync-control-center
        match:namespace = swaync-control-center
        blur = true
        ignore_alpha = 0.5
      }
    '';
  };
}
