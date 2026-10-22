{
  config,
  lib,
  pkgs,
  ...
}: let
  c = config.lib.stylix.colors.withHashtag;
in
  lib.mkIf config.profiles.desktopUser.enable {
    # notify-send for scripts (rofi-wifi.sh, rofi-bluetooth.sh, ...)
    home.packages = [pkgs.libnotify];

    # Stylix's swaync theme is flat; style it here, palette still from stylix.
    stylix.targets.swaync.enable = false;

    services.swaync = {
      enable = true;
      style = ''
        * {
          font-family: "DejaVu Sans";
          font-size: 11px;
        }

        .notification-row {
          outline: none;
        }

        .notification {
          margin: 6px 12px;
          border-radius: 12px;
        }

        .notification-content {
          background: ${c.base01};
          border: 1px solid ${c.base02};
          border-left: 3px solid ${c.base0D};
          border-radius: 12px;
          padding: 12px;
        }

        /* Fixed alert red: base08 can be non-red in wallpaper-derived palettes. */
        .notification.critical .notification-content,
        .notification-row.critical .notification-content {
          border-left: 3px solid #f38ba8;
        }

        .summary {
          color: ${c.base05};
          font-weight: bold;
          font-size: 12px;
        }

        .body {
          color: ${c.base04};
        }

        .time {
          color: ${c.base03};
          font-size: 10px;
        }

        .close-button {
          background: transparent;
          color: ${c.base04};
          border-radius: 100%;
          margin: 6px;
          padding: 2px;
        }

        .close-button:hover {
          background: #f38ba8;
          color: ${c.base00};
        }

        .notification-action {
          margin: 6px 4px 0 4px;
          border-radius: 8px;
          border: none;
          background: ${c.base02};
          color: ${c.base05};
        }

        .notification-action:hover {
          background: ${c.base0D};
          color: ${c.base00};
        }

        /* Control center: translucent so the blur layerrule shows through; cards stay solid. */
        .control-center {
          background: alpha(${c.base00}, 0.55);
          border: 1px solid ${c.base02};
          border-radius: 16px;
          padding: 12px;
          margin: 8px;
          color: ${c.base05};
        }

        .control-center .notification-row .notification-background .notification-content {
          background: ${c.base01};
        }

        .widget-title {
          color: ${c.base05};
          font-size: 14px;
          margin: 6px 4px;
        }

        .widget-title > button {
          background: ${c.base02};
          color: ${c.base05};
          border: none;
          border-radius: 8px;
          padding: 4px 10px;
        }

        .widget-title > button:hover {
          background: ${c.base0D};
          color: ${c.base00};
        }

        .widget-dnd {
          color: ${c.base05};
          margin: 6px 4px;
        }

        .widget-dnd > switch {
          background: ${c.base02};
          border: none;
          border-radius: 12px;
        }

        .widget-dnd > switch:checked {
          background: ${c.base0D};
        }

        .widget-dnd > switch slider {
          background: ${c.base05};
          border-radius: 100%;
        }

        .floating-notifications.background .notification-row .notification-background {
          background: transparent;
        }
      '';
      settings = {
        positionX = "right";
        positionY = "top";
        timeout = 6;
        timeout-low = 4;
        timeout-critical = 0;
        notification-window-width = 400;
        control-center-width = 400;
        hide-on-clear = true;
        widgets = ["title" "dnd" "notifications"];
        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd = {
            text = "Do Not Disturb";
          };
        };
      };
    };
  }
