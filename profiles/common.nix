{
  config,
  lib,
  options,
  ...
}: {
  # Relative import: the profile works without the flake's homeModules.
  imports = [
    ../modules/home/lang
    ../modules/home/starship.nix
    ../modules/home/tmux.nix
    ../modules/home/zsh.nix
  ];

  options.profiles.common.enable = lib.mkEnableOption "common home configuration";

  config = lib.mkIf config.profiles.common.enable (lib.mkMerge [
    {
      lang.nix.enable = true;
      shell = {
        starship.enable = true;
        tmux.enable = true;
        zsh.enable = true;
      };

      # omninix maps these into home.persistence on hosts with /persist.
      omninix.persistence.directories = [
        ".gnupg"
        ".local/share/nvim"
        ".local/state/nvim"
        ".ssh"
      ];

      xdg.enable = true;
      # XDG_DOWNLOAD_DIR etc., so apps agree on ~/Downloads, ~/Documents, ...
      xdg.userDirs = {
        enable = true;
        # Export XDG_DOWNLOAD_DIR etc. too (the pre-26.05 default).
        setSessionVariables = true;
      };

      programs = {
        home-manager.enable = true;
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
    }

    # Editor, when nixievim's HM module is imported.
    (lib.optionalAttrs (options ? programs.nixievim) {
      programs.nixievim = {
        enable = true;
        neovide.enable = true;
      };
    })
  ]);
}
