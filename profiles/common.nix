{
  config,
  lib,
  pkgs,
  osConfig,
  secretsPath,
  ...
}:
lib.mkIf (lib.elem "common" config.profiles) (
let
  ageKeyFile = "${config.home.homeDirectory}/.config/sops-nix/key.txt";
in
{
  home.persistence = lib.mkIf (lib.elem "impermanent" osConfig.roles) {
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

  home.sessionVariables.SOPS_AGE_KEY_FILE = ageKeyFile;

  sops = {
    age.keyFile = ageKeyFile;
    defaultSopsFormat = "yaml";
    defaultSopsFile = secretsPath + "/users/${config.home.username}.yaml";
  };
})
