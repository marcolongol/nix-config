# Claude Code settings.json: statusline, sandbox, permissions, hooks
{
  inputs,
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    settings = {
      alwaysThinkingEnabled = true;
      outputStyle = "Concise"; # built-in
      statusLine = {
        type = "command";
        command = "bash \"${inputs.claude-ponytail}/hooks/ponytail-statusline.sh\"";
      };
      # Don't auto-run MCP servers from cloned repos
      enableAllProjectMcpServers = false;

      # bwrap around Bash only; Bash(...) allow rules are the unsandboxed fallback.
      sandbox = {
        enabled = true;

        # Deny sops secrets.d dirs, not the `secrets` symlinks (bwrap can't mask those).
        credentials.files = [
          {
            path = "~/.ssh";
            mode = "deny";
          }
          {
            path = "~/.gnupg";
            mode = "deny";
          }
          {
            path = "/run/user/1000/secrets.d";
            mode = "deny";
          }
          {
            path = "/run/secrets.d";
            mode = "deny";
          }
        ];

        # Egress allowlist; anything else prompts. Extend when a fetch fails.
        network.allowedDomains = [
          "github.com"
          "api.github.com"
          "codeload.github.com"
          "objects.githubusercontent.com"
          "raw.githubusercontent.com"
          "cache.nixos.org"
          "channels.nixos.org"
          "registry.npmjs.org"
          "pypi.org"
          "files.pythonhosted.org"
          "crates.io"
          "static.crates.io"
          "proxy.golang.org"
          "sum.golang.org"
        ];
      };
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      permissions = {
        allow = [
          # File operations
          "Edit"
          "Write"
          "Read"

          # Search and navigation
          "Grep"
          "Glob"
          "WebSearch"
          "WebFetch"

          # Shell — safe patterns
          "Bash(git *)"
          "Bash(nix *)"
          "Bash(nixos-rebuild *)"
          "Bash(home-manager *)"
          "Bash(npm *)"
          "Bash(npx *)"
          "Bash(node *)"
          "Bash(cargo *)"
          "Bash(go *)"
          "Bash(python *)"
          "Bash(pip *)"
          "Bash(ls *)"
          "Bash(cat *)"
          "Bash(head *)"
          "Bash(tail *)"
          "Bash(wc *)"
          "Bash(sort *)"
          "Bash(grep *)"
          "Bash(rg *)"
          "Bash(fd *)"
          "Bash(find *)"
          "Bash(which *)"
          "Bash(echo *)"
          "Bash(pwd)"
          "Bash(mkdir *)"
          "Bash(cp *)"
          "Bash(mv *)"
          "Bash(jq *)"
          "Bash(sed *)"
          "Bash(awk *)"
          "Bash(diff *)"
          "Bash(gh *)"
          # curl intentionally not allowed
          "Bash(* --version)"
          "Bash(* --help)"

          # IDE integration
          "LSP"
          "mcp__ide__getDiagnostics"

          # MCP servers
          "mcp__plugin_hm_github__*"
          "mcp__plugin_hm_context7__*"
          "mcp__plugin_hm_mcp-nixos__*"
          "mcp__chrome-devtools__*"

          # Agents
          "Agent"
        ];
        deny = [
          # Dangerous operations still require confirmation
          "Bash(rm -rf *)"
          "Bash(rm -r *)"
          "Bash(git push --force *)"
          "Bash(git push -f *)"
          "Bash(git reset --hard *)"
          "Bash(git checkout -- *)"
          "Bash(git clean *)"
          "Bash(sudo *)"
          "Bash(chmod 777 *)"
        ];
      };

      # Auto-format edited Nix files with the flake formatter (alejandra)
      hooks = {
        PostToolUse = [
          {
            matcher = "Edit|MultiEdit|Write";
            hooks = [
              {
                type = "command";
                command = "f=$(${lib.getExe pkgs.jq} -r '.tool_input.file_path'); [[ $f == *.nix ]] && ${lib.getExe pkgs.alejandra} \"$f\" || true";
              }
            ];
          }
        ];
      };
    };
  };
}
