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
      anytype
      keymapp
      obsidian
      scrcpy
      signal-desktop
      spotify
      telegram-desktop
      tz
      vim
      qgis-ltr
    ];

    sessionVariables = {
      EDITOR = "vim";
      TERMINAL = "ghostty";
    };
  };

  xdg.configFile."tz/conf.toml".text = ''
    [[zones]]
    id = "America/Los_Angeles"
    name = "Seattle"

    [[zones]]
    id = "Europe/Berlin"
    name = "Poland"

    [[zones]]
    id = "Asia/Kolkata"
    name = "India"
  '';

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
    # settings replaces matchBlocks; keys are upstream ssh_config directives.
    settings = {
      "*" = {
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
        Compression = true;
      };
      "github.com" = {
        User = "git";
      };
    };
  };

  programs.spotify-player.enable = true;

  persistentFolders = [
    ".config/1Password"
    ".local/share/Steam"
    ".config/spotify"
    ".config/anytype"
    ".config/Signal"
  ];

  # Persist only cert.pem; per-tunnel credentials live in sops.
  persistentFiles = [
    ".cloudflared/cert.pem"
  ];

  sops = {
    secrets = {
      user-secret = {};
      dockerhub-auth = {};
      github-pat = {};
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
