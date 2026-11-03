{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.worker.enable = lib.mkEnableOption "worker profile (for work-related tools)";

  config = lib.mkIf config.profiles.worker.enable {
    home.packages = with pkgs; [
      simplescreenrecorder
      todoist
      webex
    ];

    programs.libreoffice.enable = true;
    # Remmina plus its tray service at login
    services.remmina.enable = true;

    omninix.persistence.directories = [
      ".config/remmina"
      ".local/share/remmina"
    ];
  };
}
