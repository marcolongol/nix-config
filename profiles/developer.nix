{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.developer.enable = lib.mkEnableOption "developer tools and CLI configuration";

  config = lib.mkIf config.profiles.developer.enable {
    home.packages = with pkgs; [
      aria2
      bzip2.dev
      cabextract
      cdrkit
      chntpw
      cilium-cli
      cmake
      curl
      dbeaver-bin
      dig
      docker-buildx
      docker-client
      docker-compose
      fluxcd
      gh
      github-copilot-cli
      gnumake
      go-task
      k3d
      knot-dns
      krew
      kubectl
      kubectx
      kubernetes-helm
      libffi.dev
      minijinja
      ncurses.dev
      ngrok
      openssl.dev
      pkg-config
      psqlodbc
      readline.dev
      restic
      rsync
      sox
      systemctl-tui
      talhelper
      talosctl
      tcpdump
      tilt
      wget
      wimlib
      wl-clipboard
      xz.dev
      zlib.dev
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
            command = ''git diff --staged | claude -p --setting-sources "" --system-prompt "You are a git commit message generator. You receive a staged diff on stdin and output ONLY the raw commit message (Conventional Commits: subject line plus optional body). No markdown, no code blocks, no backticks, no preamble, no explanation, no trailing commentary. Plain text commit message only." | wl-copy && echo "Commit message copied to clipboard."'';
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

    programs.kubecolor = {
      enable = true;
      enableAlias = true;
      enableZshIntegration = true;
    };

    programs.kubeswitch = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.k9s = {
      enable = true;
    };

    programs.mise = {
      enable = true;
      enableZshIntegration = true;
    };

    persistentFolders = [
      ".config/Code"
      ".config/direnv"
      ".config/github-copilot"
      ".copilot"
      ".krew"
      ".kube"
      ".local/share/DBeaverData"
    ];

    persistentFiles = [ ];

    home.sessionPath = ["$HOME/.krew/bin"];

    # ----------------
    # SECTION: k3d
    # ----------------
    home.file.".config/k3d/dev-cluster.yaml".text = ''
      apiVersion: k3d.io/v1alpha5
      kind: Simple
      metadata:
        name: dev
      image: rancher/k3s:v1.31.5-k3s1
      servers: 1
      agents: 2
      registries:
        create:
          name: registry.localhost
          host: "0.0.0.0"
          hostPort: "5000"
        config: |
          mirrors:
            "registry.localhost:5000":
              endpoint:
                - "http://registry.localhost:5000"
      ports:
        - port: 80:80
          nodeFilters:
            - loadbalancer
        - port: 443:443
          nodeFilters:
            - loadbalancer
    '';

    programs.zsh.shellAliases = {
      k3d-dev = "k3d cluster create --config ~/.config/k3d/dev-cluster.yaml --kubeconfig-update-default";
      k = "kubectl";
      kn = "kubens";
      kx = "kubectx";
    };
  };
}
