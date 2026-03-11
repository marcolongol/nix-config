{pkgs, ...}: let
  # Powerline glyphs (MesloLGS Nerd Font)
  sep = ""; # U+E0B0 right-pointing filled
  sep_l = ""; # U+E0B2 left-pointing filled

  weatherScript = pkgs.writeShellScript "tmux-weather" ''
    cache="/tmp/tmux-weather"
    if [ ! -f "$cache" ] || [ "$(( $(date +%s) - $(date +%s -r "$cache" 2>/dev/null || echo 0) ))" -gt 1800 ]; then
      json=$(curl -sf --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=47.4829&longitude=-122.2171&current=temperature_2m,weathercode&temperature_unit=fahrenheit&timezone=America%2FLos_Angeles") || { printf "? N/A" > "$cache"; cat "$cache"; exit 0; }
      temp=$(printf '%s' "$json" | grep -o '"temperature_2m":[0-9.]*' | grep -o '[0-9.]*$')
      code=$(printf '%s' "$json" | grep -o '"weathercode":[0-9]*' | grep -o '[0-9]*$')
      case "$code" in
        0)            icon="☀" ;;
        1|2|3)        icon="⛅" ;;
        45|48)        icon="🌫" ;;
        51|53|55|61|63|65|80|81|82) icon="🌧" ;;
        71|73|75|77|85|86) icon="❄" ;;
        95|96|99)     icon="⛈" ;;
        *)            icon="?" ;;
      esac
      printf '%s %s°F' "$icon" "$temp" > "$cache"
    fi
    cat "$cache"
  '';
in {
  programs.tmux = {
    enable = true;
    keyMode = "vi";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      vim-tmux-navigator
      resurrect
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
        '';
      }
    ];
    extraConfig = ''
      set -g base-index 1
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g mouse on

      # Status bar
      set -g status-interval 60

      # Left: session name
      set -g status-left-length 40
      set -g status-left " #S ${sep}"

      # Window list
      set -g window-status-separator ""
      set -g window-status-format " #I:#W "
      set -g window-status-current-format "${sep} #I:#W ${sep}"

      # Right: weather + time
      set -g status-right-length 80
      set -g status-right "${sep_l} #(${weatherScript}) ${sep_l} %H:%M  %d %b "

      # Window navigation
      bind -n M-0 select-window -t 0
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4

      # Open split panes in the current directory
      bind '"' split-window -v -p 40 -c "#{pane_current_path}"
      bind % split-window -h -p 40 -c "#{pane_current_path}"
    '';
  };

  programs.zsh.initContent = ''
    # create/attach tmux session if not already inside one
    if [ -z "$TMUX" ] && command -v tmux >/dev/null 2>&1; then
        tmux attach -t dev || tmux new -s dev
    fi
  '';

  persistentFolders = [
    ".local/share/tmux"
  ];
}
