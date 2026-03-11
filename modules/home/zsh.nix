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
    defaultKeymap = "viins";
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      cat = "bat";
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
    plugins = [
      {
        name = "fzf-tab";
        src = "${pkgs.zsh-fzf-tab}/share/fzf-tab";
      }
    ];
    initContent = ''
      # Completion behaviour
      setopt auto_menu complete_in_word always_to_end
      zstyle ':completion:*:*:*:*:*' menu select
      zstyle ':completion:*' special-dirs true
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors \
        'di=01;34:ln=01;36:so=01;35:pi=40;33:ex=01;32:bd=40;33;01:cd=40;33;01:su=37;41:sg=30;43:tw=30;42:ow=34;42'

      # Directory navigation
      setopt auto_cd auto_pushd pushd_ignore_dups pushdminus

      # Misc
      setopt multios long_list_jobs interactive_comments

      # Bracketed paste & url quoting
      autoload -Uz bracketed-paste-magic url-quote-magic
      zle -N bracketed-paste bracketed-paste-magic
      zle -N self-insert url-quote-magic

      # Cursor shape: beam in insert mode, block in normal mode
      zle-keymap-select() {
        if [[ $KEYMAP == vicmd ]]; then
          echo -ne '\e[1 q'
        else
          echo -ne '\e[5 q'
        fi
      }
      zle -N zle-keymap-select
      echo -ne '\e[5 q'

      # Accept autosuggestion with alt+l
      bindkey '^[l' autosuggest-accept

      # Navigate history with alt+j/k (matches typed prefix)
      bindkey '^[k' history-beginning-search-backward
      bindkey '^[j' history-beginning-search-forward

      # fzf-tab
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
      zstyle ':fzf-tab:*' switch-group '<' '>'
      zstyle ':fzf-tab:*' fzf-bindings 'alt-j:down' 'alt-k:up'
    '';
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
      style = "compact";
      show_preview = true;
      filter_mode_shell_up_arrow = "session";
    };
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

  persistentFolders = [
    ".local/share/atuin"
  ];
}
