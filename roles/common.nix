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
    time.timeZone = "America/Los_Angeles";

    networking = {
      inherit hostName;
      networkmanager.enable = true;
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
