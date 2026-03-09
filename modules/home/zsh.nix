{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    bottom
    dust
    procs
  ];

  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    defaultKeymap = "emacs";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      cat = "bat";
      cd = "z";
      top = "btm";
      du = "dust";
      ps = "procs";
    };
    history = {
      append = true;
      extended = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      size = 10000;
      share = true;
    };
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "fzf" "docker" "kubectl" "helm" "history" "aliases"];
    };
    initContent = ''
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors \
        'di=01;34:ln=01;36:so=01;35:pi=40;33:ex=01;32:bd=40;33;01:cd=40;33;01:su=37;41:sg=30;43:tw=30;42:ow=34;42'
    '';
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
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

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "always";
    git = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      batdiff
      batman
      # batgrep
      prettybat
    ];
    config = {
      pager = "less -FR";
    };
  };

  persistentFiles = [
    ".zsh_history"
  ];
}