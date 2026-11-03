# NFSv4 automounts of one export's shares into every active user's home
# (/home/<user>/<share>), over AUTH_SYS.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.roles.nfsClient;
  fsType = "nfs";
  mountOptions = [
    "x-systemd.automount"
    "noauto"
    "x-systemd.idle-timeout=600"
    "x-systemd.mount-timeout=100ms"
    "_netdev"
    "rw"
    "soft"
    "nfsvers=4"
    "rsize=1048576"
    "wsize=1048576"
    "timeo=5"
    "retrans=3"
    "noatime"
    "async"
    "tcp"
  ];
in {
  options.roles.nfsClient = {
    enable = lib.mkEnableOption "NFS client mounts";
    server = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "nas.local:/volume1";
      description = "NFS export the shares live under (`host:/path`).";
    };
    shares = lib.mkOption {
      type = lib.types.listOf (lib.types.strMatching "^[A-Za-z0-9._-]+$");
      default = [];
      example = ["Documents" "Media"];
      description = "Shares under `server`, each mounted at /home/<user>/<share>.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.server != null;
        message = "roles.nfsClient.server must be set (e.g. \"nas.local:/volume1\")";
      }
    ];

    services.rpcbind.enable = true;
    boot.supportedFilesystems = ["nfs"];
    boot.kernelModules = ["nfs"];

    # Persist NFS state for file locking and state monitoring
    omninix.persistence.directories = ["/var/lib/nfs"];

    fileSystems = builtins.listToAttrs (
      lib.flatten (
        map (
          userName:
            map (name: {
              name = "/home/${userName}/${name}";
              value = {
                inherit fsType;
                options = mountOptions;
                device = "${cfg.server}/${name}";
              };
            })
            cfg.shares
        )
        config.omninix.activeUsers
      )
    );

    environment.systemPackages = with pkgs; [nfs-utils];
  };
}
