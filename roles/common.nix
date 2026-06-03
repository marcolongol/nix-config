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
        # Hand DNS to systemd-resolved (DoT, see services.resolved below).
        dns = "systemd-resolved";
      };
      firewall = {
        allowedTCPPorts = [ 22 80 443 5900 ];
        allowedTCPPortRanges = [
          { from = 3000; to = 3010; }
          { from = 4200; to = 4210; }
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
    ];

    services = {
      # Encrypted DNS over TLS, opportunistic so captive portals still work.
      # Fallback resolvers carry #hostname for cert validation.
      resolved = {
        enable = true;
        dnssec = "true";
        dnsovertls = "opportunistic";
        fallbackDns = [
          "1.1.1.1#cloudflare-dns.com"
          "9.9.9.9#dns.quad9.net"
        ];
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
      udev.packages = [ pkgs.yubikey-personalization ];
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

    nix.settings = {
      experimental-features = ["nix-command" "flakes"];
      auto-optimise-store = true;
    };

    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

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
