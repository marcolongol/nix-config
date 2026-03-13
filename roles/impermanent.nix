{
  config,
  lib,
  ...
}: {
  options.roles.impermanent.enable = lib.mkEnableOption "ephemeral root with /persist";

  config = lib.mkIf config.roles.impermanent.enable {
    environment.persistence."/persist" = {
      enable = true;
      hideMounts = true;
      directories =
        [
          "/var/log"
          "/var/lib/bluetooth"
          "/var/lib/nixos"
          "/var/lib/systemd/coredump"
          "/etc/NetworkManager/system-connections"
          "/etc/ssh"
        ]
        ++ config.persistentFolders;
      files =
        [
          "/etc/machine-id"
        ]
        ++ config.persistentFiles;
    };
  };
}