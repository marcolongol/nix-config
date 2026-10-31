{
  config,
  lib,
  pkgs,
  secretsPath,
  ...
}: {
  options.profiles.common.enable = lib.mkEnableOption "common home configuration";

  config = lib.mkIf config.profiles.common.enable {
    # omninix maps these into home.persistence on hosts with /persist.
    omninix.persistence.directories = [
      "Pictures"
      "Work"
      "Personal"
      ".ssh"
      ".gnupg"
      ".local/share/nvim"
      ".local/state/nvim"
    ];

    xdg.enable = true;

    programs = {
      home-manager.enable = true;
      nixievim = {
        enable = true;
        neovide.enable = true;
      };
      ghostty = {
        enable = true;
        settings = {
          font-size = 10;
          window-padding-x = 8;
          window-padding-y = 8;
          scrollback-limit = 10000;
          shell-integration-features = "cursor,sudo,title";
          background-opacity = 0.90;
        };
        systemd.enable = true;
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
