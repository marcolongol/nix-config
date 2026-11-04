{
  config,
  lib,
  pkgs,
  ...
}: {
  # Relative import: the profile works without the flake's homeModules.
  imports = [
    ../modules/home/direnv.nix
    ../modules/home/git.nix
    ../modules/home/lang
    ../modules/home/session-path.nix
  ];

  options.profiles.developer.enable = lib.mkEnableOption "developer tools and CLI configuration";

  config = lib.mkIf config.profiles.developer.enable {
    shell = {
      direnv.enable = true;
      git.enable = true;
    };

    lang = {
      dotnet.enable = true;
      go.enable = true;
      nodejs.enable = true;
      python.enable = true;
    };

    home.packages = with pkgs; [
      bzip2.dev
      cabextract
      cdrkit
      chntpw
      cilium-cli
      cmake
      curl
      dig
      docker-buildx
      docker-client
      docker-compose
      fluxcd
      freetds
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
      postgresql
      psqlodbc
      readline.dev
      restic
      rsync
      sox
      sqlcmd
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

    programs = {
      # gh plus its git credential helper for github.com
      gh.enable = true;
      aria2.enable = true;
      dbeaver.enable = true;
      github-copilot-cli.enable = true;

      git.settings.core.editor = "nvim";

      jq = {
        enable = true;
      };

      lazygit = {
        enable = true;
        settings = {
          git.diffRenderers = [
            {
              colorArg = "always";
              command = "delta --color-only --dark --paging=never";
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

      lazydocker = {
        enable = true;
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        # extraConfig needs a default host block; merges with any the user adds.
        settings."*" = {};
        extraConfig = ''
          AddKeysToAgent yes
        '';
      };

      kubecolor = {
        enable = true;
        enableAlias = true;
        enableZshIntegration = true;
      };

      kubeswitch = {
        enable = true;
        enableZshIntegration = true;
      };

      k9s = {
        enable = true;
      };

      mise = {
        enable = true;
        enableZshIntegration = true;
      };

      zsh.shellAliases = {
        k3d-dev = "k3d cluster create --config ~/.config/k3d/dev-cluster.yaml --kubeconfig-update-default";
        k = "kubectl";
        kn = "kubens";
        kx = "kubectx";
      };
    };

    home.sessionPathAppend = ["$HOME/.krew/bin"];

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
      # Registry and ingress on loopback only: docker-published ports bypass
      # the host firewall, so 0.0.0.0 would expose them to the LAN.
      registries:
        create:
          name: registry.localhost
          host: "127.0.0.1"
          hostPort: "5000"
        config: |
          mirrors:
            "registry.localhost:5000":
              endpoint:
                - "http://registry.localhost:5000"
      ports:
        - port: 127.0.0.1:80:80
          nodeFilters:
            - loadbalancer
        - port: 127.0.0.1:443:443
          nodeFilters:
            - loadbalancer
    '';

    omninix.persistence.directories = [
      ".config/github-copilot"
      ".copilot"
      ".krew"
      ".kube"
      ".local/share/DBeaverData"
    ];
  };
}
