{
  config,
  pkgs,
  ...
}: let
  pubKeys = import ./pubkeys.nix;
  gpgPubKey = pkgs.writeText "lucas-gpg-pubkey.asc" pubKeys.gpg.publicKey;
in {
  home.stateVersion = "26.05";

  profiles = {
    common.enable = true;
    developer.enable = true;
    worker.enable = true;
  };

  home = {
    packages = with pkgs; [
      anytype
      keymapp
      qgis-ltr
      scrcpy
      signal-desktop
      spotify
      telegram-desktop
      tz
    ];

    sessionVariables.TERMINAL = "ghostty";
  };

  shell.tmux = {
    autoAttach = true;
    weather = {
      latitude = "43.1566";
      longitude = "-77.6088";
      timezone = "America/New_York";
      unit = "fahrenheit";
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

  programs = {
    # vim-full with vim-sensible; also sets EDITOR
    vim = {
      enable = true;
      defaultEditor = true;
    };

    obsidian.enable = true;

    # Applies where the desktop role enables zen.
    zen-browser.policies.Homepage = {
      URL = "https://homepage.marcolongo.dev";
      Locked = true;
      StartPage = "homepage";
    };

    gpg = {
      enable = true;
      publicKeys = [
        {
          source = gpgPubKey;
          trust = "ultimate";
        }
      ];
    };

    git.settings = {
      user = {
        name = "Lucas Marcolongo";
        email = "lucas@marcolongo.dev";
        signingKey = pubKeys.gpg.fingerprint;
      };
      init.defaultBranch = "main";
      commit.gpgSign = true;
    };

    ssh = {
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

    spotify-player.enable = true;
  };

  omninix.persistence = {
    directories = [
      "Personal"
      "Pictures"
      "Work"
      ".config/1Password"
      ".config/spotify"
      ".config/anytype"
      ".config/Signal"
    ];
    # Persist only cert.pem; per-tunnel credentials live in sops.
    files = [".cloudflared/cert.pem"];
  };

  sops = {
    # Decrypt with the YubiKey's GPG key; the file is omninix's default
    # (secrets/users/lucas.yaml).
    gnupg.home = "${config.home.homeDirectory}/.gnupg";
    secrets = {
      user-secret = {};
      dockerhub-auth = {};
      github-pat = {};
    };
    templates = {
      docker-config = {
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
      # gh login rendered from the PAT; don't use `gh auth login/logout`
      gh-hosts = {
        path = "${config.home.homeDirectory}/.config/gh/hosts.yml";
        content = ''
          github.com:
            user: marcolongol
            oauth_token: ${config.sops.placeholder.github-pat}
            git_protocol: https
        '';
        mode = "0600";
      };
    };
  };
}
