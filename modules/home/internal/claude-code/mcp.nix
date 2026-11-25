# MCP servers
{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    mcpServers = {
      github = {
        command = "${pkgs.writeShellScript "github-mcp-server-wrapper" ''
          export GITHUB_PERSONAL_ACCESS_TOKEN="$(cat ${config.sops.secrets.github-pat.path})"
          exec ${lib.getExe pkgs.github-mcp-server} stdio "$@"
        ''}";
      };

      context7 = {
        # Version pinned for reproducibility
        command = "${pkgs.nodejs}/bin/npx";
        args = ["-y" "@upstash/context7-mcp@3.2.1"];
      };

      # Launches its own headless chromium on demand (pipe, throwaway profile),
      # so no DevTools port is left listening. Only where chromium is installed.
      chrome-devtools = lib.mkIf config.programs.chromium.enable {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "chrome-devtools-mcp@1.12.0"
          "--executable-path"
          "${config.programs.chromium.finalPackage}/bin/chromium"
          "--headless"
          "--isolated"
          "--acceptInsecureCerts"
        ];
      };

      mcp-nixos = {
        command = "${lib.getExe pkgs.mcp-nixos}";
      };

      # Jira/Confluence/Bitbucket; OAuth on first use via /mcp
      atlassian = {
        type = "http";
        url = "https://mcp.atlassian.com/v1/mcp";
      };

      # Work DBs; sources/read-only rules in ~/Work/dbhub.toml, passwords injected by op
      dbhub = {
        command = "${pkgs.writeShellScript "dbhub-mcp-wrapper" ''
          case "$PWD/" in
            "$HOME/Work/"*) ;;
            *) echo "dbhub: only enabled under ~/Work" >&2; exit 1 ;;
          esac
          exec op run --env-file "$HOME/Work/.env.op" -- \
            ${pkgs.nodejs}/bin/npx -y @bytebase/dbhub@2.1.0 --transport stdio --config "$HOME/Work/dbhub.toml"
        ''}";
      };
    };
  };
}
