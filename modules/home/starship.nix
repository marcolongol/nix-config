{...}: {
  programs.starship = {
    enable = true;
    settings = {
      format = "$all$character";
      right_format = "$kubernetes$cmd_duration$time";
      add_newline = true;
      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
      };
      battery = {
        disabled = false;
        full_symbol = "🔋";
        charging_symbol = "⚡";
        discharging_symbol = "🔌";
        unknown_symbol = "❓";
      };
      memory_usage = {
        disabled = false;
        threshold = 70;
      };
      time = {
        disabled = false;
        format = "[🕒 $time](dimmed white)";
        use_12hr = false;
      };
      kubernetes = {
        disabled = false;
        format = "[$symbol$context( \\($namespace\\))](cyan bold) ";
      };
      cmd_duration = {
        min_time = 2000;
        format = "[⏱ $duration](dimmed yellow) ";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };
      line_break.disabled = false;
    };
  };
}
