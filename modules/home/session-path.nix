# home.sessionPathAppend: like home.sessionPath, but appended to PATH. A
# user-writable directory ahead of /run/wrappers/bin could shadow sudo.
{
  config,
  lib,
  ...
}: {
  options.home.sessionPathAppend = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    example = ["$HOME/.krew/bin"];
    description = "Directories to append to PATH (expanded by the shell, like home.sessionPath).";
  };

  config = lib.mkIf (config.home.sessionPathAppend != []) {
    home.sessionVariablesExtra = ''
      export PATH="$PATH:${lib.concatStringsSep ":" config.home.sessionPathAppend}"
    '';
  };
}
