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
    kubernetes-helm
    talosctl
    kubectl
    krew
    ngrok
    restic
  ];

  programs.git = {
    enable = true;
    extraConfig = {
      core.editor = "vim";
      pull.rebase = true;
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

  programs.ssh = {
    enable = true;
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
