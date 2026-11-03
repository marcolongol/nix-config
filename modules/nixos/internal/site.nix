# Site configuration for these machines: the personal values that the shared
# roles leave to the flake using them. Set on upstream options where they exist.
{
  config,
  inputs,
  lib,
  hostName,
  secretsPath,
  ...
}: let
  # Wallpaper rotation: deterministic pick from ./wallpapers/ based on flake
  # lastModified. Each comin sync produces a new timestamp -> new index ->
  # different wallpaper + theme. Pure-Nix friendly, no runtime daemon.
  wallpaperDir = inputs.self + "/wallpapers";
  wallpaperFiles = lib.pipe (builtins.readDir wallpaperDir) [
    (lib.filterAttrs (n: t:
      t
      == "regular"
      && builtins.any (ext: lib.hasSuffix ext (lib.toLower n)) [".jpg" ".jpeg" ".png" ".webp"]))
    lib.attrNames
    (builtins.sort builtins.lessThan)
  ];
  wallpaperIndex = lib.mod inputs.self.lastModified (builtins.length wallpaperFiles);
  selectedWallpaper = wallpaperDir + "/${builtins.elemAt wallpaperFiles wallpaperIndex}";
in {
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

    (lib.mkIf config.roles.desktop.enable {
      stylix.image = selectedWallpaper;

      # VPN agents for these machines.
      programs.surfshark.enable = true;
      programs.harmony-sase.enable = true;
      # TEMPORARY: same posture-check spoof as nixos-lt — macOS-only server-side
      # profile hits Linux too. Remove once the admin-console profile is corrected.
      programs.harmony-sase.spoofDpcFiles = ["/dev/null/MacOS_Prohibited_on_TEOCO_VPN"];

      # Let the 1Password extension in zen talk to the desktop app.
      environment.etc = {
        "1password/custom_allowed_browsers" = {
          text = ''
            .zen-wrapped
            zen
          '';
          mode = "0755";
        };
      };
    })

    (lib.mkIf config.roles.nfsClient.enable {
      roles.nfsClient = {
        server = "10.0.0.4:/volume1";
        shares = ["Backup" "Documents" "Downloads" "K8s" "Media" "Shared"];
      };
    })
  ];
}
