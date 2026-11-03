# Hostname, time zone, deploy (comin), extra open ports and shared secrets are
# per-site: set them in your own config (this flake: its internal site module).
{
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  options.roles.common.enable = lib.mkEnableOption "common system configuration";

  config = lib.mkIf config.roles.common.enable (lib.mkMerge [
    {
      # Fails closed if anything re-introduces passwordless sudo on a host with repo users.
      assertions = [
        {
          assertion = config.omninix.activeUsers == [] || config.security.sudo.wheelNeedsPassword;
          message = "security.sudo.wheelNeedsPassword must be true on hosts with active users";
        }
      ];

      networking = {
        networkmanager = {
          enable = true;
          # Switch to "stable" if captive portals or DHCP reservations break.
          wifi.macAddress = "random";
          ethernet.macAddress = "random";
          wifi.scanRandMacAddress = true;
          dns = "systemd-resolved";
        };
        firewall = {
          allowedTCPPorts = [22];
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
        # Opportunistic so captive portals work; fallbacks carry #hostname for cert validation.
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
        # Resolve .local names; publishing this host is left to the site.
        avahi = {
          enable = true;
          nssmdns4 = true;
          openFirewall = true;
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
        # Cap journal size and retention (docker logs ship here too).
        journald.settings.Journal = {
          SystemMaxUse = "2G";
          MaxRetentionSec = "1month";
        };
        udev.packages = [pkgs.yubikey-personalization];
      };

      boot.zfs.forceImportRoot = false;
      boot.loader.systemd-boot.configurationLimit = 10;
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

      # nh clean replaces nix.gc; don't enable both.
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 5";
        };
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
    }

    # Prebuilt index for comma and command-not-found, when nix-index-database's
    # module is imported. optionalAttrs, not mkIf: mkIf false still defines the
    # option, which errors when that module isn't imported.
    (lib.optionalAttrs (options ? programs.nix-index-database) {
      programs.nix-index-database.comma.enable = true;
    })
  ]);
}
