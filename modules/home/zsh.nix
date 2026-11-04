# zsh with completion (carapace, fzf-tab), history (atuin), zoxide, eza and
# bat. Note the aliases: cat, top, du and ps run bat, btm, dust and procs.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.shell.zsh;
in {
  options.shell.zsh = {
    enable = lib.mkEnableOption "zsh with completion, history and CLI tools";

    icons = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Show file icons in eza listings. Needs a Nerd Font in the terminal.";
    };

    prettybat = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install prettybat, which bundles formatters for every language it supports (about 3 GB).";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      dust
      procs
    ];

    programs = {
      bottom.enable = true;
      ripgrep.enable = true;
      fd.enable = true;
      # tldr pages; cache refreshed by a systemd timer
      tealdeer.enable = true;
      # Completions for 2000+ CLIs, shown through fzf-tab; bridges keep native ones for the rest
      carapace = {
        enable = true;
        enableZshIntegration = true;
        environment.CARAPACE_BRIDGES = "zsh,bash";
      };

      zsh = {
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
          saveNoDups = true;
          path = "${config.home.homeDirectory}/.zsh_history";
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

          # Get SRI hash for a URL (works for any file type)
          nix-hash-url() {
            nix-prefetch-url "$1" 2>/dev/null | tail -1 | xargs -I{} nix hash to-sri --type sha256 {}
          }

          # Accept autosuggestion with alt+l
          bindkey '^[l' autosuggest-accept

          # Navigate history with alt+j/k (matches typed prefix)
          bindkey '^[k' history-beginning-search-backward
          bindkey '^[j' history-beginning-search-forward

          # fzf-tab; group labels enable switch-group
          zstyle ':completion:*:descriptions' format '[%d]'
          zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
          zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always $realpath'
          zstyle ':fzf-tab:*' switch-group '<' '>'
          zstyle ':fzf-tab:*' fzf-bindings 'alt-j:down' 'alt-k:up'
        '';
      };

      atuin = {
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

      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

      eza = {
        enable = true;
        enableZshIntegration = true;
        icons = lib.mkIf cfg.icons "always";
        git = true;
      };

      fzf = {
        enable = true;
        enableZshIntegration = true;
        # Atuin owns Ctrl-R (sourced after fzf); drop fzf's history widget so
        # home-manager stops warning about the collision.
        historyWidget.zsh.command = "";
      };

      bat = {
        enable = true;
        extraPackages = with pkgs.bat-extras;
          [
            batdiff
            batman
            # batgrep
          ]
          ++ lib.optional cfg.prettybat prettybat;
        config = {
          pager = "less -FR";
        };
      };
    };

    omninix.persistence.files = [
      ".zsh_history"
    ];

    omninix.persistence.directories = [
      ".cache/tealdeer"
      ".local/share/atuin"
      ".local/share/zoxide"
    ];
  };
}
