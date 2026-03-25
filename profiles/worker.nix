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
    ];

    persistentFolders = [
      ".config/remmina"
      ".local/share/remmina"
    ];
  };
}
