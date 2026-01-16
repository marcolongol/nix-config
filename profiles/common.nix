{
  config,
  lib,
  pkgs,
  osConfig,
  secretsPath,
  ...
}:
lib.mkIf (lib.elem "common" config.profiles) {
  home.persistence = lib.mkIf (lib.elem "impermanent" osConfig.roles) {
    "/persist" = {
      directories =
        [
          "Pictures"
          "Work"
          "Personal"
          ".ssh"
          ".local/share/nvim"
          ".local/state/nvim"
        ]
        ++ config.persistentFolders;
      files = [".config/sops-nix/key.txt"] ++ config.persistentFiles;
    };
  };

  xdg.enable = true;

  home.packages = with pkgs; [
    vim
  ];

  programs = {
    home-manager.enable = true;
    nixievim.enable = true;
    alacritty.enable = true;
    btop.enable = true;
  };

  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops-nix/key.txt";
    defaultSopsFormat = "yaml";
    defaultSopsFile = secretsPath + "/users/${config.home.username}.yaml";
  };
}
