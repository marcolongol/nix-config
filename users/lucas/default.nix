{
  config,
  pkgs,
  ...
}: let
  pubKeys = import ./pubkeys.nix;
  gpgPubKey = pkgs.writeText "lucas-gpg-pubkey.asc" pubKeys.gpg.publicKey;
in {
  home.stateVersion = "25.11";

  profiles = {
    common.enable = true;
    desktopUser.enable = true;
    developer.enable = true;
    gamer.enable = true;
    worker.enable = true;
  };

  home = {
    packages = with pkgs; [
      vim
      freecad
      spotify
      keymapp
      telegram-desktop
    ];

    sessionVariables = {
      EDITOR = "vim";
      TERMINAL = "alacritty";
    };
  };

  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = gpgPubKey;
        trust = "ultimate";
      }
    ];
  };

  programs.git = {
    settings = {
      user = {
        name = "Lucas Marcolongo";
        email = "lucas@marcolongo.dev";
        signingKey = pubKeys.gpg.fingerprint;
      };
      init.defaultBranch = "main";
      commit.gpgSign = true;
    };
  };

  programs.ssh = {
    enableDefaultConfig = false;
    matchBlocks = {
      "*" = {
        serverAliveInterval = 60;
        serverAliveCountMax = 3;
        compression = true;
      };
      "github.com" = {
        user = "git";
      };
    };
  };

  programs.spotify-player = {
    enable = true;
    settings = {
      autostart = true;
      noTrayIcon = false;
      startMinimized = true;
    };
  };

  persistentFolders = [
    ".config/1Password"
    ".local/share/Steam"
  ];

  sops = {
    secrets = {
      user-secret = {};
      dockerhub-auth = {};
    };
    templates.docker-config = {
      path = "${config.home.homeDirectory}/.docker/config.json";
      content = ''
        {
          "auths": {
            "https://index.docker.io/v1/": {
              "auth": "${config.sops.placeholder.dockerhub-auth}"
            }
          }
        }
      '';
      mode = "0600";
    };
  };
}
