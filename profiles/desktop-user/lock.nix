{
  config,
  lib,
  ...
}: let
  c = config.lib.stylix.colors;
in
  lib.mkIf config.profiles.desktopUser.enable {
    # Full custom lock styling below replaces stylix's default background.
    stylix.targets.hyprlock.enable = false;

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          hide_cursor = true;
          grace = 2;
          ignore_empty_input = true;
        };
        background = [
          {
            monitor = "";
            path = "screenshot";
            blur_passes = 3;
            blur_size = 8;
            noise = 1.17e-2;
            contrast = 0.8916;
            brightness = 0.8172;
            vibrancy = 0.1696;
          }
        ];
        input-field = [
          {
            monitor = "";
            size = "300, 50";
            position = "0, -20";
            halign = "center";
            valign = "center";
            outline_thickness = 2;
            dots_size = 0.33;
            dots_spacing = 0.15;
            dots_center = true;
            rounding = 12;
            outer_color = "rgb(${c.base0D})";
            inner_color = "rgb(${c.base01})";
            font_color = "rgb(${c.base05})";
            check_color = "rgb(${c.base0B})";
            fail_color = "rgb(${c.base08})";
            fade_on_empty = false;
            placeholder_text = "<i>Enter password…</i>";
            fail_text = "<i>$FAIL ($ATTEMPTS)</i>";
          }
        ];
        label = [
          {
            monitor = "";
            text = "$TIME";
            color = "rgb(${c.base05})";
            font_size = 96;
            font_family = "MesloLGS Nerd Font";
            position = "0, 220";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "cmd[update:3600000] date +\"%A, %d %B\"";
            color = "rgb(${c.base04})";
            font_size = 22;
            font_family = "MesloLGS Nerd Font";
            position = "0, 120";
            halign = "center";
            valign = "center";
          }
          {
            monitor = "";
            text = "    $USER";
            color = "rgb(${c.base0D})";
            font_size = 16;
            font_family = "MesloLGS Nerd Font";
            position = "0, 60";
            halign = "center";
            valign = "center";
          }
        ];
      };
    };

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
  }
