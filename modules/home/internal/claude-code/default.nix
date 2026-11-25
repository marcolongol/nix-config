{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  # Lives in a subdir of the official plugins monorepo
  frontendDesign = "${inputs.claude-plugins-official}/plugins/frontend-design";

  # Upstream ships bare skills/ without a plugin manifest; wrap it
  angularEcosystem = pkgs.runCommand "angular-ecosystem-plugin" {} ''
    mkdir -p $out/.claude-plugin
    ln -s ${inputs.claude-angular-skills}/skills $out/skills
    echo '{"name":"angular-ecosystem","version":"0.0.0","description":"Angular + Nx ecosystem skills (oguzhan18)"}' > $out/.claude-plugin/plugin.json
  '';
in {
  imports = [./settings.nix ./mcp.nix ./lsp.nix];

  config = lib.mkIf config.profiles.developer.enable {
    # Sandbox deps; without them claude-code runs Bash unsandboxed
    home.packages = [pkgs.bubblewrap pkgs.socat];

    # Plugins whose manifest paths (hooks, skills) go through top-level entries: link the whole dir,
    # since programs.claude-code.plugins symlinks per-entry and Claude rejects paths resolving outside the plugin.
    home.file = lib.mapAttrs' (name: src: lib.nameValuePair "${config.programs.claude-code.configDir}/skills/${name}" {source = src;}) {
      ponytail = inputs.claude-ponytail; # lifecycle hooks need `node` on PATH (modules/home/lang/nodejs.nix)
      ui-ux-pro-max = inputs.claude-ui-ux-pro-max; # design-system generator (50+ styles, palettes, font pairings)
    };

    programs.claude-code = {
      enable = true;

      # Attrset so plugin dir names stay stable
      plugins = {
        # Frontend UI/design plugins
        frontend-design = frontendDesign; # official Anthropic: deliberate aesthetic before any CSS

        # Official Anthropic workflow plugins
        claude-code-setup = "${inputs.claude-plugins-official}/plugins/claude-code-setup"; # recommends hooks, skills, MCP servers, subagents per repo
        commit-commands = "${inputs.claude-plugins-official}/plugins/commit-commands"; # /commit, /commit-push-pr, /clean_gone
        angular-ecosystem = angularEcosystem; # Angular + Nx ecosystem skills
      };

      agentsDir = ./agents;
      rulesDir = ./rules;
      skills = {
        interview-me = ./skills/interview-me.md;
        ticket = ./skills/ticket.md;
      };
      outputStyles = {
        caveman = ./output-styles/caveman.md;
      };
    };

    # ────────────────────────────────────────────
    # SECTION: Persistence
    # ────────────────────────────────────────────
    omninix.persistence.directories = [
      ".claude"
    ];

    omninix.persistence.files = [
      ".claude.json"
    ];
  };
}
