{pkgs, ...}: let
  pubKeys = import ./pubkeys.nix;
  gpgPubKey = pkgs.writeText "lucas-gpg-pubkey.asc" pubKeys.gpg.publicKey;
in {
  home.stateVersion = "25.11";

  profiles = ["common" "desktop-user" "developer" "gamer"];

  home = {
    packages = with pkgs; [
      vim
      remmina
      webex
      freecad
      spotify
      todoist
      keymapp
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
    ".config/remmina"
    ".local/share/remmina"
    ".local/share/Steam"
  ];

  sops = {
    secrets = {
      user-secret = {
        mode = "0400";
      };
    };
  };
}
