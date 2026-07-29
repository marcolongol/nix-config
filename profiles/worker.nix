{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.worker.enable = lib.mkEnableOption "worker profile (for work-related tools)";

  config = lib.mkIf config.profiles.worker.enable {
    home.packages = with pkgs; [
      remmina
      webex
      todoist
      libreoffice
      simplescreenrecorder
    ];

    persistentFolders = [
      ".config/remmina"
      ".local/share/remmina"
    ];
  };
}
