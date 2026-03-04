{
  lib,
  pkgs,
  ...
}: let
  pubKeys = import ./pubkeys.nix;
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

    file.".ssh/authorized_keys".text = pubKeys.ssh;
  };

  programs.git = {
    settings = {
      user = {
        name = "Lucas Marcolongo";
        email = "lucas_marco@live.com";
        signingKey = pubKeys.ssh;
      };
      init.defaultBranch = "main";
      gpg.format = "ssh";
      "gpg \"ssh\"".program = "${lib.getExe' pkgs._1password-gui "op-ssh-sign"}";
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
        addKeysToAgent = "yes";
      };
      "github.com" = {
        user = "git";
      };
    };
    extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';
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
