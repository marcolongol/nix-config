{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "developer" config.profiles) {
  home.packages = with pkgs; [
    curl
    wget
    gnumake
    cmake
    docker-compose
    docker-buildx
    docker-client
    kubernetes-helm
    talosctl
    kubectl
    krew
    ngrok
    restic
    fluxcd
    cilium-cli
    dbeaver-bin
    dig
    tilt
    minijinja
    go-task
    aria2
    cabextract
    wimlib
    chntpw
    rsync
    cdrkit
    gh
  ];

  programs.git = {
    enable = true;
    settings = {
      core.editor = "vim";
      pull.rebase = true;

      # Security & Performance
      push.autoSetupRemote = true;
      fetch.prune = true;
      rebase.autoStash = true;
      rerere.enabled = true;

      # Better Diffs & Merges
      diff.algorithm = "histogram";
      diff.colorMoved = "default";
      merge.conflictStyle = "zdiff3";

      # Branch Management
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.claude-code = {
    enable = true;
  };

  programs.jq = {
    enable = true;
  };

  programs.lazygit = {
    enable = true;
  };

  programs.lazydocker = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
  };

  programs.k9s = {
    enable = true;
  };

  persistentFolders = [
    ".claude"
    ".config/github-copilot"
    ".config/Code"
    ".krew"
  ];

  persistentFiles = [
    ".claude.json"
    ".kube/config"
  ];

  home.sessionPath = ["$HOME/.krew/bin"];
}
