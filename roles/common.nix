{
  config,
  lib,
  pkgs,
  hostName,
  secretsPath,
  ...
}:
lib.mkIf (lib.elem "common" config.roles) {
  time.timeZone = "America/Los_Angeles";

  networking = {
    inherit hostName;
    networkmanager.enable = true;
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
  ];

  services = {
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

  system.autoUpgrade = {
    enable = true;
    dates = "daily";
    allowReboot = false;
  };

  users.defaultUserShell = pkgs.zsh;

  programs.zsh.enable = true;

  security.sudo.wheelNeedsPassword = false;

  sops = {
    age = {
      sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
      keyFile = "/var/lib/sops-nix/key.txt";
      generateKey = true;
    };

    defaultSopsFormat = "yaml";
    defaultSopsFile = secretsPath + "/${hostName}.yaml";

    secrets = {
      shared-secret = {
        sopsFile = secretsPath + "/shared.yaml";
      };
    };
  };
}
