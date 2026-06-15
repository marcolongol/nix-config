{
  config,
  lib,
  pkgs,
  hostName,
  secretsPath,
  ...
}: {
  options.roles.common.enable = lib.mkEnableOption "common system configuration";

  config = lib.mkIf config.roles.common.enable {
    time.timeZone = "America/New_York";

    networking = {
      inherit hostName;
      networkmanager = {
        enable = true;
        # Randomize MAC per-connection for privacy on untrusted networks.
        # Switch to "stable" if captive portals or DHCP reservations break.
        wifi.macAddress = "random";
        ethernet.macAddress = "random";
        wifi.scanRandMacAddress = true;
        dns = "systemd-resolved";
      };
      firewall = {
        allowedTCPPorts = [22 80 443 5900];
        allowedTCPPortRanges = [
          {
            from = 3000;
            to = 3010;
          }
          {
            from = 4200;
            to = 4210;
          }
        ];
        allowPing = true;
      };
    };

    environment.systemPackages = with pkgs; [
      ncdu
      unzip
      zip
      vim
      git
      curl
      wget
      htop
      tree
      pfetch
      sops
      yubikey-manager
      notepad-next
      nix-output-monitor
      nvd
    ];

    services = {
      # Encrypted DNS over TLS, opportunistic so captive portals still work.
      # Fallback resolvers carry #hostname for cert validation.
      resolved = {
        enable = true;
        settings.Resolve = {
          DNSSEC = "allow-downgrade";
          DNSOverTLS = "opportunistic";
          FallbackDNS = [
            "1.1.1.1#cloudflare-dns.com"
            "9.9.9.9#dns.quad9.net"
          ];
        };
      };
      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          addresses = true;
        };
      };
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
        };
      };
      fwupd.enable = true;
      smartd.enable = true;
      udisks2.enable = true;
      devmon.enable = true;
      pcscd.enable = true;
      # Cap journal disk usage and retention so logs don't grow unbounded
      # (docker logs ship here too via logDriver = "journald").
      journald.extraConfig = ''
        SystemMaxUse=2G
        MaxRetentionSec=1month
      '';
      udev.packages = [pkgs.yubikey-personalization];
      comin = {
        enable = true;
        remotes = [
          {
            name = "origin";
            url = "https://github.com/marcolongol/nix-config";
            branches.main.name = "main";
          }
        ];
      };
    };

    boot.zfs.forceImportRoot = false;
    boot.loader.systemd-boot.configurationLimit = 10;
    # Quiet, low-verbosity boot. Hosts can append to this list as needed.
    boot.kernelParams = ["loglevel=3" "quiet"];

    boot.tmp = {
      useTmpfs = true;
      tmpfsSize = "50%";
      cleanOnBoot = true;
    };

    systemd.oomd = {
      enable = true;
      enableRootSlice = true;
      enableUserSlices = true;
    };

    documentation = {
      man.enable = true;
      dev.enable = true;
    };

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };

    # nh: modern rebuild frontend (`nh os switch`), wraps nix-output-monitor
    # for readable build output and shows an nvd package diff after each build.
    # nh clean replaces nix.gc (don't run both).
    programs.nh = {
      enable = true;
      flake = "/home/lucas/Personal/nix-config";
      clean = {
        enable = true;
        extraArgs = "--keep-since 7d --keep 5";
      };
    };

    # nix-index-database ships the prebuilt index so `comma` (`, <cmd>`) and
    # command-not-found work without ever running `nix-index` locally.
    programs.nix-index-database.comma.enable = true;

    users.defaultUserShell = pkgs.zsh;

    programs = {
      gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
      };
      zsh.enable = true;
    };

    hardware.gpgSmartcards.enable = true;

    # Passwordless sudo by default. Flipped to require auth when a user
    # declares a YubiKey (see modules/nixos/default.nix).
    security.sudo.wheelNeedsPassword = lib.mkDefault false;

    sops = {
      age = {
        sshKeyPaths =
          if config.roles.impermanent.enable
          then ["/persist/etc/ssh/ssh_host_ed25519_key"]
          else ["/etc/ssh/ssh_host_ed25519_key"];
      };

      defaultSopsFormat = "yaml";
      defaultSopsFile = secretsPath + "/${hostName}.yaml";

      secrets = {
        shared-secret = {
          sopsFile = secretsPath + "/shared.yaml";
        };
      };
    };
  };
}
