# git with delta for diffs and opinionated defaults: rebase on pull, prune on
# fetch, rerere, histogram diffs, zdiff3 conflicts. Identity, signing and
# editor are left to the user.
{
  config,
  lib,
  ...
}: {
  options.shell.git.enable = lib.mkEnableOption "git with delta and opinionated defaults";

  config = lib.mkIf config.shell.git.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
      };
    };

    programs.git = {
      enable = true;
      settings = {
        pull.rebase = true;

        # Security & Performance
        push.autoSetupRemote = true;
        fetch.prune = true;
        rebase.autoStash = true;
        rerere.enabled = true;

        # Better Diffs & Merges
        diff.algorithm = "histogram";
        diff.colorMoved = "default";
        diff.colorMovedWS = "allow-indentation-change";
        merge.conflictStyle = "zdiff3";

        # Branch Management
        branch.sort = "-committerdate";
        tag.sort = "version:refname";
      };
    };
  };
}
