{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  # notify-send for scripts (rofi-wifi.py, rofi-bluetooth.sh, ...)
  home.packages = [pkgs.libnotify];

  services.swaync = {
    enable = true;
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
