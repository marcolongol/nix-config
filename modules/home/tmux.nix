{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
    ];
    extraConfig = ''
      set -g base-index 1

      # Mouse support
      set -g mouse on

      # Status bar
      set -g status-bg colour234
      set -g status-fg colour137

      # Window navigation
      bind -n M-0 select-window -t 0
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4

      # Open split panes in the current directory
      bind '"' split-window -v -p 30 -c "#{pane_current_path}"
      bind % split-window -h -p 30 -c "#{pane_current_path}"
    '';
  };

  programs.zsh.initContent = ''
    # create/attach tmux session if not already inside one
    if [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
        tmux attach -t dev || tmux new -s dev
    fi
  '';
}
