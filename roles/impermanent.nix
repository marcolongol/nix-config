{
  config,
  lib,
  ...
}:
lib.mkIf (lib.elem "impermanent" config.roles) {
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
}
