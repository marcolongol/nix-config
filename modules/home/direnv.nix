# direnv with nix-direnv: `use flake` in an .envrc loads a dev shell on cd,
# cached so it survives garbage collection.
{
  config,
  lib,
  ...
}: {
  options.shell.direnv.enable = lib.mkEnableOption "direnv with nix-direnv";

  config = lib.mkIf config.shell.direnv.enable {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    omninix.persistence.directories = [".config/direnv"];
  };
}
