{config, ...}: let
  # Standalone HM has no stylix; fall back to base16 "Default Dark".
  c =
    config.lib.stylix.colors or {
      base00 = "181818";
      base01 = "282828";
      base02 = "383838";
      base03 = "585858";
      base04 = "b8b8b8";
      base05 = "d8d8d8";
      base06 = "e8e8e8";
      base07 = "f8f8f8";
      base08 = "ab4642";
      base09 = "dc9656";
      base0A = "f7ca88";
      base0B = "a1b56c";
      base0C = "86c1b9";
      base0D = "7cafc2";
      base0E = "ba8baf";
      base0F = "a16946";
    };
in {
  programs.starship = {
    enable = true;
    settings = {
      format = ''
        [](fg:#${c.base01})$os$username$hostname[](fg:#${c.base01} bg:#${c.base02})$directory[](fg:#${c.base02} bg:#${c.base00})$git_branch$git_status[](fg:#${c.base00})$nodejs$python$rust$golang$java$docker_context$nix_shell[](fg:#${c.base00})
        $character'';
      right_format = "$battery$kubernetes$cmd_duration$time";
      add_newline = true;

      os = {
        disabled = false;
        style = "bg:#${c.base01} fg:#${c.base0D} bold";
        symbols = {
          NixOS = " 󱄅";
        };
      };

      username = {
        show_always = true;
        style_user = "bg:#${c.base01} fg:#${c.base0D} bold";
        style_root = "bg:#${c.base01} fg:#${c.base08} bold";
        format = "[ $user]($style)";
      };

      hostname = {
        ssh_only = false;
        style = "bg:#${c.base01} fg:#${c.base04}";
        format = "[@$hostname ]($style)";
      };

      directory = {
        style = "bg:#${c.base02} fg:#${c.base0C} bold";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncate_to_repo = true;
        substitutions = {
          "~" = "󰋜 ~";
        };
      };

      git_branch = {
        style = "bg:#${c.base00} fg:#${c.base0B} bold";
        format = "[ $symbol$branch ]($style)";
      };

      git_status = {
        style = "bg:#${c.base00} fg:#${c.base0A}";
        format = "[$all_status$ahead_behind]($style)[](fg:#${c.base00}) ";
        conflicted = "󰞇 ";
        ahead = "⇡\${count} ";
        behind = "⇣\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        untracked = "? ";
        stashed = "󰏗 ";
        modified = "! ";
        staged = "+ ";
        renamed = "» ";
        deleted = "✘ ";
      };

      nodejs = {
        style = "bg:#${c.base00} fg:#${c.base0B}";
        format = "[ $symbol$version ]($style)";
      };

      python = {
        style = "bg:#${c.base00} fg:#${c.base0A}";
        format = "[ $symbol$version ]($style)";
      };

      rust = {
        style = "bg:#${c.base00} fg:#${c.base08}";
        format = "[ $symbol$version ]($style)";
      };

      golang = {
        style = "bg:#${c.base00} fg:#${c.base0C}";
        format = "[ $symbol$version ]($style)";
      };

      java = {
        style = "bg:#${c.base00} fg:#${c.base0A}";
        format = "[ $symbol$version ]($style)";
      };

      docker_context = {
        style = "bg:#${c.base00} fg:#${c.base0D}";
        format = "[ $symbol$context ]($style)";
      };

      nix_shell = {
        disabled = false;
        style = "bg:#${c.base00} fg:#${c.base0E}";
        format = "[ $symbol$state ]($style)";
        heuristic = true;
        symbol = " 󱄅 ";
      };

      character = {
        success_symbol = "[❯](bold #${c.base0B})";
        error_symbol = "[❯](bold #${c.base08})";
      };

      kubernetes = {
        disabled = false;
        style = "bold #${c.base0E}";
        format = "[$symbol$context( \\($namespace\\))]($style) ";
        symbol = "󱃾 ";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[󱦟 $duration](dimmed #${c.base0A}) ";
      };

      time = {
        disabled = false;
        format = "[ 󰥔 $time](dimmed #${c.base04})";
        use_12hr = false;
      };

      battery = {
        disabled = false;
        full_symbol = "󰁹 ";
        charging_symbol = "󰂄 ";
        discharging_symbol = "󰂃 ";
        unknown_symbol = "󰁽 ";
      };
    };
  };
}
