{
  config,
  lib,
  pkgs,
  ...
}: let
  device = "10.0.0.4:/volume1";
  fsType = "nfs";
  options = [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=600"
    "rw"
    "hard"
    "nfsvers=4"
    "rsize=1048576"
    "wsize=1048576"
    "timeo=5"
    "retrans=3"
    "noatime"
    "async"
    "tcp"
  ];
  nfsMounts = ["Backup" "Documents" "Downloads" "K8s" "Media" "Shared"];
in
  lib.mkIf (lib.elem "nfs-client" config.roles) {
    services.rpcbind.enable = true;
    boot.supportedFilesystems = ["nfs"];
    boot.kernelModules = ["nfs"];

    # Persist NFS state for file locking and state monitoring
    persistentFolders = ["/var/lib/nfs"];

    fileSystems = builtins.listToAttrs (
      lib.flatten (
        map (
          userName:
            map (name: {
              name = "/home/${userName}/${name}";
              value = {
                inherit options fsType;
                device = "${device}/${name}";
              };
            })
            nfsMounts
        )
        config.hostUsers
      )
    );

    environment.systemPackages = with pkgs; [nfs-utils];
  }
