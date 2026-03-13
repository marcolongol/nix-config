{
  config,
  lib,
  pkgs,
  osConfig,
  secretsPath,
  ...
}: {
  options.profiles.common.enable = lib.mkEnableOption "common home configuration";

  config = lib.mkIf config.profiles.common.enable {
    home.persistence = lib.mkIf osConfig.roles.impermanent.enable {
      "/persist" = {
        directories =
          [
            "Pictures"
            "Work"
            "Personal"
            ".ssh"
            ".gnupg"
            ".local/share/nvim"
            ".local/state/nvim"
          ]
          ++ config.persistentFolders;
        files = config.persistentFiles;
      };
    };

    xdg.enable = true;

    home.packages = with pkgs; [
      vim
    ];

    programs = {
      home-manager.enable = true;
      nixievim.enable = true;
      ghostty = {
        enable = true;
        settings = {
          window-padding-x = 8;
          window-padding-y = 8;
          scrollback-limit = 10000;
          shell-integration-features = "cursor,sudo,title";
        };
      };
      btop.enable = true;
    };

    sops = {
      gnupg.home = "${config.home.homeDirectory}/.gnupg";
      defaultSopsFormat = "yaml";
      defaultSopsFile = secretsPath + "/users/${config.home.username}.yaml";
    };
  };
}