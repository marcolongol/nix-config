# Site configuration for these machines: the personal values that the shared
# roles leave to the flake using them. Set on upstream options where they exist.
{
  config,
  lib,
  hostName,
  secretsPath,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.roles.common.enable {
      networking.hostName = hostName;
      time.timeZone = "America/New_York";

      # Dev port ranges stay open for LAN testing.
      networking.firewall.allowedTCPPortRanges = [
        {
          from = 3000;
          to = 3010;
        }
        {
          from = 4200;
          to = 4210;
        }
      ];

      # Announce this host on the LAN (<host>.local).
      services.avahi.publish = {
        enable = true;
        addresses = true;
      };

      programs.nh.flake = "/home/lucas/Personal/nix-config";

      # GitOps: comin pulls main and switches this host.
      services.comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = "https://github.com/marcolongol/nix-config";
            branches.main.name = "main";
          }
        ];
      };

      # Key paths, format and host file come from omninix.
      sops.secrets.shared-secret.sopsFile = secretsPath + "/shared.yaml";
    })

    (lib.mkIf config.roles.nfsClient.enable {
      roles.nfsClient = {
        server = "10.0.0.4:/volume1";
        shares = ["Backup" "Documents" "Downloads" "K8s" "Media" "Shared"];
      };
    })
  ];
}
