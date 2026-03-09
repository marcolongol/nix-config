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
    k3d
    wl-clipboard
  ];

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
      core.editor = "nvim";
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
    settings = {
      git.pagers = [
        {
          colorArg = "always";
          pager = "delta --color-only --dark --paging=never";
        }
      ];
      customCommands = [
        {
          key = "<c-g>";
          context = "files";
          description = "Generate AI commit message (copies to clipboard)";
          command = ''git diff --staged | claude -p "Generate a git commit message following the Conventional Commits spec for this diff. Output only the commit message (subject line + optional body), nothing else." | wl-copy && echo "Commit message copied to clipboard."'';
          output = "terminal";
        }
      ];
    };
  };

  programs.lazydocker = {
    enable = true;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    extraConfig = ''
      AddKeysToAgent yes
      ServerAliveInterval 60
      ServerAliveCountMax 3
    '';
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
