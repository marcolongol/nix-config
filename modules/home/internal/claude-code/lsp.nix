# LSP servers for Claude's LSP tool
{
  lib,
  pkgs,
  ...
}: {
  programs.claude-code = {
    lspServers = {
      nix = {
        command = "${lib.getExe pkgs.nixd}";
        args = [];
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };
      typescript = {
        command = "${lib.getExe pkgs.typescript-language-server}";
        args = ["--stdio"];
        extensionToLanguage = {
          ".ts" = "typescript";
          ".tsx" = "typescriptreact";
          ".js" = "javascript";
          ".jsx" = "javascriptreact";
        };
      };
      python = {
        command = "${lib.getExe' pkgs.pyright "pyright-langserver"}";
        args = ["--stdio"];
        extensionToLanguage = {
          ".py" = "python";
        };
      };
      lua = {
        command = "${lib.getExe pkgs.lua-language-server}";
        args = [];
        extensionToLanguage = {
          ".lua" = "lua";
        };
      };
      bash = {
        command = "${lib.getExe pkgs.bash-language-server}";
        args = ["start"];
        extensionToLanguage = {
          ".sh" = "shellscript";
          ".bash" = "shellscript";
        };
      };
    };
  };
}
