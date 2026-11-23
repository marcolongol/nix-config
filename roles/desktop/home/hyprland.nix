{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  # zen when its module is imported (browser.nix), else the chromium installed here.
  browser =
    if options ? programs.zen-browser
    then "zen-beta"
    else "chromium";
in {
  services.hyprpaper = {
    settings = {
      splash = false;
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # 0.57 dropped hyprlang; hyprland.conf is ignored.
    configType = "lua";
    # uwsm owns the session. HM's hyprland-session.target stop cascades into uwsm's
    # graphical-session and kills Hyprland ~2s after login.
    systemd.enable = false;
    plugins = [
      pkgs.hyprlandPlugins.hyprbars
      # hyprspace doesn't build against hyprland 0.56; re-add with $mod+Tab and plugin.overview below once it does.
      # pkgs.hyprlandPlugins.hyprspace
    ];
    # Rendered as hl.config({...}); stylix merges its colors in here too.
    settings.config = {
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
      animations.enabled = true;
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
      plugin = {
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
        };
      };
    };
    extraConfig = ''
      local mod = "SUPER"
      local terminal = "ghostty"
      local filemanager = "nautilus"
      local browser = "${browser}"
      local menu = "rofi -show drun -show-icons"

      hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
      hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
      hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1} } })

      hl.animation({ leaf = "windows",          enabled = true, speed = 4, bezier = "easeOutQuint" })
      hl.animation({ leaf = "windowsIn",        enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "windowsOut",       enabled = true, speed = 3, bezier = "easeOutQuint", style = "popin 87%" })
      hl.animation({ leaf = "border",           enabled = true, speed = 6, bezier = "linear" })
      hl.animation({ leaf = "fade",             enabled = true, speed = 4, bezier = "easeInOutCubic" })
      hl.animation({ leaf = "workspaces",       enabled = true, speed = 5, bezier = "easeOutQuint", style = "slide" })
      hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "easeOutQuint", style = "slidevert" })

      hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
      hl.bind(mod .. " + F", hl.dsp.exec_cmd(browser))
      hl.bind(mod .. " + E", hl.dsp.exec_cmd(filemanager))
      hl.bind(mod .. " + C", hl.dsp.window.close())
      hl.bind(mod .. " + M", hl.dsp.exit())
      hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
      hl.bind(mod .. " + CTRL + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
      hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
      hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
      hl.bind(mod .. " + space", hl.dsp.exec_cmd(menu))
      -- hl.bind(mod .. " + Tab", hl.dsp.exec_cmd("hyprctl dispatch overview:toggle"))

      local dirs = { h = "left", j = "down", k = "up", l = "right" }
      local resize = { h = { -20, 0 }, j = { 0, 20 }, k = { 0, -20 }, l = { 20, 0 } }
      for key, dir in pairs(dirs) do
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
        hl.bind(mod .. " + CTRL + " .. key, hl.dsp.window.resize({ x = resize[key][1], y = resize[key][2], relative = true }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
      end

      for i = 1, 10 do
        local key = i % 10
        hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
      hl.bind(mod .. " + D", hl.dsp.workspace.toggle_special("minimized"))
      hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

      hl.bind(mod .. " + P", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
      hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))

      -- Rofi launchers
      hl.bind(mod .. " + X", hl.dsp.exec_cmd("rofi-power.sh"))
      hl.bind(mod .. " + W", hl.dsp.exec_cmd("rofi-wifi.sh"))
      hl.bind(mod .. " + B", hl.dsp.exec_cmd("rofi-bluetooth.sh"))
      hl.bind(mod .. " + semicolon", hl.dsp.exec_cmd("rofi -show emoji"))
      hl.bind(mod .. " + equal", hl.dsp.exec_cmd("rofi -show calc -no-show-match -no-sort"))
      hl.bind(mod .. " + SHIFT + Tab", hl.dsp.exec_cmd("rofi -show window"))

      hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | wl-copy]]))

      -- Workspace prev/next (also emitted by MX Master gesture button via logiops)
      hl.bind(mod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind(mod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))

      hl.bind(mod .. " + comma", hl.dsp.focus({ monitor = "-1" }))
      hl.bind(mod .. " + period", hl.dsp.focus({ monitor = "+1" }))
      hl.bind(mod .. " + SHIFT + comma", hl.dsp.window.move({ monitor = "-1" }))
      hl.bind(mod .. " + SHIFT + period", hl.dsp.window.move({ monitor = "+1" }))

      local media = { locked = true, repeating = true }
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), media)
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), media)
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), media)
      hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), media)
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), media)
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), media)

      hl.window_rule({ name = "float-center-pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, center = true })
      hl.window_rule({ name = "float-center-blueman", match = { class = "^(\\.blueman-manager-wrapped)$" }, float = true, center = true })
      hl.window_rule({ name = "nautilus-opacity", match = { class = "^(org.gnome.Nautilus)$" }, opacity = "0.90 0.82" })
      hl.window_rule({ name = "float-nautilus-props", match = { class = "^(org.gnome.Nautilus)$", title = "^(.*Properties.*)$" }, float = true })
      hl.window_rule({ name = "float-center-1password", match = { class = "^(1password)$" }, float = true, center = true })
      hl.window_rule({ name = "float-portal-filechooser", match = { class = "^(xdg-desktop-portal-gtk)$" }, float = true, size = "monitor_w*0.6 monitor_h*0.6", center = true })
      hl.window_rule({ name = "pip", match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true, keep_aspect_ratio = true })
      hl.window_rule({ name = "idleinhibit-fullscreen", match = { class = "^(.*)$" }, idle_inhibit = "fullscreen" })

      -- Blur behind the translucent swaync control center; ignore_alpha skips transparent gaps.
      hl.layer_rule({ name = "blur-swaync-control-center", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0.5 })

      -- Last so a hyprbars load failure only drops the buttons. Render right-to-left.
      hl.plugin.hyprbars.add_button({ bg_color = "rgb(f38ba8)", fg_color = "rgb(1e1e2e)", size = 13, icon = "", action = "hyprctl dispatch 'hl.dsp.window.close()'" })
      hl.plugin.hyprbars.add_button({ bg_color = "rgb(f9e2af)", fg_color = "rgb(1e1e2e)", size = 13, icon = "", action = [[hyprctl dispatch 'hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })']] })
      hl.plugin.hyprbars.add_button({ bg_color = "rgb(a6e3a1)", fg_color = "rgb(1e1e2e)", size = 13, icon = "", action = [[hyprctl dispatch 'hl.dsp.window.move({ workspace = "special:minimized", follow = false })']] })
    '';
  };
}
