{
  lib,
  pkgs,
  ...
}: {
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
    ];

    sessionVariables = {
      EDITOR = "vim";
      TERMINAL = "alacritty";
    };
  };

  programs.git = {
    settings = {
      user = {
        name = "Lucas Marcolongo";
        email = "lucas_marco@live.com";
        signingKey = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDNFeQPhPMI2W5Ot5B+Cs7XK5F2TmvjsAiLVD0Ix+tM8AUKjmjLc/Fvt3UvPqY+U09yfu1S6QTL41Q0xQln8MUU+r5DLWh01UiA4obC/m76MGP1Vv3tGubP6+18bJXxNXB7vhPsy5ruTjgAsbXep3PVKjjqZfdrKAiLBF0Zj380KOapZVTDf51vS5ClEFSTX6xgX6VB3rtjYs8aB2GxpAIniLTOmfhkednYhs3bdNRv/MLO0J6SL4+Z//gEg4bq9VsYZviOulBLt2176kk4fyPc2azdIII2Apk2Ulqr9RGvIJ5LVbNpsKDoLzEYPFW/sJ82z4o9uSYXMruKSQWrqkCo5GxsGAi7xTGcVFO0wKPxr3wWZW+K35V7jyWAJFamsnXQUoeXlfIu/DzUfgJ+TSILWWr6ZrV/y0ohkSp9hs1ByDsjmmLEI5SZDjDDs07zaEa6VO9eDuh3xsqB8s2vsaJ+fegDKxm08//rltAXhSx45EADCOzsCYNXteP8eexuqgBQAL11OSCKp6PX4SGDGnu9dip0jpDzZqVpY/AcIxFJsY7niKw+FIsT8lM+4Gxm4w3nUWGnKLTnxqZ4XMeU1a8dna9fIN1WG3i+fBqsNHD8kRuKTS/0BibXAnnlK9FBak1onbg5fuqlSvsV41EscfEbP6g4IkXqVevTK8Ud5ihNSQ==";
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
