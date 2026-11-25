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

      # ────────────────────────────────────────────
      # SECTION: Settings
      # ────────────────────────────────────────────
      settings = {
        alwaysThinkingEnabled = true;
        outputStyle = "concise";
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

      # ────────────────────────────────────────────
      # SECTION: Plugins
      # ────────────────────────────────────────────
      # Attrset so plugin dir names stay stable
      plugins = {
        # Frontend UI/design plugins
        frontend-design = frontendDesign; # official Anthropic: deliberate aesthetic before any CSS

        # Official Anthropic workflow plugins
        claude-code-setup = "${inputs.claude-plugins-official}/plugins/claude-code-setup"; # recommends hooks, skills, MCP servers, subagents per repo
        commit-commands = "${inputs.claude-plugins-official}/plugins/commit-commands"; # /commit, /commit-push-pr, /clean_gone
        angular-ecosystem = angularEcosystem; # Angular + Nx ecosystem skills
      };

      # ────────────────────────────────────────────
      # SECTION: MCP Servers
      # ────────────────────────────────────────────
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
      };

      # ────────────────────────────────────────────
      # SECTION: LSP Servers
      # ────────────────────────────────────────────
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

      # ────────────────────────────────────────────
      # SECTION: Skills
      # ────────────────────────────────────────────
      skills = {
        interview-me = ''
          ---
          name: interview-me
          description: Interview the user to turn a vague request into a clear brief (job, why, rules, definition of done)
          disable-model-invocation: true
          ---

          The user has a task but not a clear prompt for it. Interview them until you can
          write a brief they agree with. Starting idea, possibly empty: $ARGUMENTS

          ## Interview
          - Before asking, read what you can find yourself (repo, files, git log, memory), so
            you only ask what the user alone can answer.
          - Use `AskUserQuestion`, 1–3 questions per round, each with concrete options built
            from what you found. Build each round on the previous answers.
          - Cover, in this order:
            1. **Job**: what to build or change, and where.
            2. **Why**: the goal behind it; this decides trade-offs.
            3. **Rules**: constraints, conventions, what must not change, what is out of scope.
            4. **Done**: how to verify it worked (tests, build, observable behavior).
          - Stop asking as soon as every section is clear. Don't ask what has a sensible
            default; note the default in the brief instead.

          ## Brief
          Show the brief in this shape:

          ```
          Job:   ...
          Why:   ...
          Rules: ...
          Done:  ...
          Defaults assumed: ...
          ```

          Ask whether it's right; revise until the user confirms.

          ## Then
          Ask with `AskUserQuestion`: start the task now, or output the brief as a
          ready-to-paste prompt. Do what they pick.
        '';

        ticket = ''
          ---
          name: ticket
          description: Start or resume a work session on a Jira ticket (SmartCkt / WebKit)
          disable-model-invocation: true
          ---

          Drive the work on ticket `$ARGUMENTS` (e.g. `SMARTCKTS-11640`).
          No ticket key given → ask for one and stop.

          The ticket folder is `~/Work/<number>/`, the key without its project prefix
          (`SMARTCKTS-11640` → `~/Work/11640/`).

          ## Mode: pick by the current directory
          - **Anywhere outside the ticket folder (e.g. the vault): bootstrap only.**
            Do Setup 2–4: fetch the Jira issue into `jira-<KEY>.json` in the ticket
            folder, set the vault line to `gate: investigate`. Then print
            `cd ~/Work/<number> && claude "/ticket <KEY>"` and stop. No investigation,
            no Conductor or DB queries in this session.
          - **Inside the ticket folder: work session.** Do the full Setup, then the Flow.

          ## Setup
          1. Read `~/Work/smartckt-context.md` in full. It is the working context for
             SmartCkt and WebKit; its rules override defaults. It holds no secrets.
          2. Credentials: only via `op run --env-file ~/Work/.env.op -- sh -c '...'`.
             Never print, echo or write a resolved value. If `op` fails, stop and say so.
          3. Ticket folder: create it with `git init` if missing; if it exists, read what
             is there and resume from the last gate reached.
             All notes, baselines, plans and deliverables for the ticket live here.
          4. Vault: in `~/Personal/obsidian-vault/01 Projects/`, pick `SmartCkt.md` or
             `WebKit.md` by where the change lands (ask if unclear). Under `## Tickets`,
             keep exactly one line per ticket:
             `- [ ] <KEY> — <short title> · gate: <investigate|questions|plan|phase N|review|QA>`
             Update the gate as the session moves. Only that line; no ticket detail in the
             vault (it syncs to GitHub).

          ## Flow
          Run the gated session flow from the context file (§9). Every gate waits for my
          explicit approval. Read-only investigation needs no approval.
        '';
      };

      # ────────────────────────────────────────────
      # SECTION: Rules
      # ────────────────────────────────────────────
      rules = {
        security = ''
          # Security Rules

          - Never commit secrets, tokens, or API keys
          - Never hardcode credentials — use environment variables or secret managers
          - Never expose internal service ports without explicit user confirmation
          - Validate and sanitize all external inputs at system boundaries
        '';

        tooling = ''
          # Tool and Resource Usage

          ## IDE Integration (Neovim)
          - Use **LSP** tools for code intelligence — hover, go-to-definition, find-references, document symbols, call hierarchy
          - Use **getDiagnostics** to check for errors/warnings before and after edits — catch issues the same way the editor does
          - Prefer LSP navigation (goToDefinition, findReferences) over grep when tracing symbols — it's more precise
          - Use documentSymbol/workspaceSymbol to understand file and project structure before diving into code
          - Use hover to inspect types and documentation inline instead of guessing

          ## MCP Servers
          - Always prefer available MCP servers over manual alternatives
          - Use **context7** as first source for library/framework documentation — never guess at APIs when docs are available
          - Use **GitHub** MCP for issue context, PR history, and code search before making assumptions
          - Use **chrome-devtools** MCP for any web testing, screenshots, or Lighthouse audits

          ## Before starting any task
          - Scan the available skills, agents, and MCP tools (including deferred ones) for a match to the task; if one fits, use it instead of doing the work by hand
          - Prefer, in order: a matching skill → a matching plugin/MCP tool → a matching agent → manual tool calls
          - Say in one line which skill/tool/agent you picked, or that none fit, so the choice is visible
          - When a task involves a library or framework, check context7 for current docs even if you think you know the API
        '';
      };

      # ────────────────────────────────────────────
      # SECTION: Agents
      # ────────────────────────────────────────────
      agents = {
        test-writer = ''
          ---
          name: test-writer
          description: Generate comprehensive tests for code changes or specified files
          model: sonnet
          color: cyan
          isolation: worktree
          memory: user
          tools: Read, Grep, Glob, Edit, Write, Bash, LSP, mcp__ide__getDiagnostics, mcp__plugin_hm_context7__*, mcp__plugin_hm_mcp-nixos__*
          ---

          You are an adversarial test writer: hunt the edge cases nobody thought about (null,
          empty, huge inputs, undefined).

          ## Available Tools
          - Use **LSP** (hover, goToDefinition, documentSymbol) to understand function signatures, types, and structure of code under test
          - Use **getDiagnostics** after writing tests to catch type errors and import issues immediately
          - Use **context7** MCP to look up the latest API and usage docs for the project's test framework before writing tests — never guess at assertion syntax or test runner config

          ## Process
          1. Read the target code and understand its behavior
          2. Identify the project's test framework by examining existing tests
          3. Use context7 to fetch current docs for that framework
          4. Plan coverage matrix: branches, edge cases, error paths
          5. Write tests covering: happy path, edge cases, error conditions, boundary values

          ## Guidelines
          - Match the existing test style exactly (naming, structure, assertions)
          - Place test files where the project convention expects them
          - Prefer realistic test data over trivial examples — boring inputs find boring bugs
          - Test behavior, not implementation details
          - If no test framework exists, ask before choosing one

          If no arguments given, write tests for files changed in `git diff`.

          $ARGUMENTS
        '';

        browser = ''
          ---
          name: browser
          description: Browse, test, and audit web pages using Chrome DevTools
          model: haiku
          color: pink
          memory: user
          tools: Read, Bash, mcp__chrome-devtools__*
          ---

          You are a thorough QA tester with Chrome DevTools access: verify everything, take
          nothing on faith.

          ## Available Tools
          - Use **chrome-devtools** MCP to navigate pages, take screenshots, fill forms, click elements, run Lighthouse audits, capture network requests, and evaluate JavaScript

          ## Capabilities
          - Navigate to URLs and interact with page elements (click, fill, type, drag)
          - Take screenshots and DOM snapshots for visual inspection
          - Run Lighthouse audits for performance, accessibility, SEO, and best practices
          - Monitor network requests and console messages for debugging
          - Emulate devices and screen sizes for responsive testing
          - Execute arbitrary JavaScript in page context
          - Trace performance and capture memory snapshots

          ## Guidelines
          - Always take a screenshot after navigation to verify state
          - For form testing, verify submission results via network requests or page changes
          - When debugging, check both console messages and network requests
          - For accessibility audits, use Lighthouse with the accessibility category

          $ARGUMENTS
        '';
      };

      # ────────────────────────────────────────────
      # SECTION: Output Styles
      # ────────────────────────────────────────────
      outputStyles = {
        concise = ''
          Give the shortest complete, correct answer. Plain grammatical sentences.

          ## Rules
          - Lead with the answer or the result. Reasoning only if asked or non-obvious.
          - No preamble ("Sure", "Great question", "Let me"), no closing recap, no offers to help further.
          - One sentence beats a list; a list beats a paragraph. Use headers only for multi-part answers.
          - When reporting work: what changed, where (`file:line`), anything left undone. Skip the narration.
          - Code blocks in full, never elided. Comment only non-obvious logic.
          - Quote error messages and technical terms exactly.
          - State uncertainty once, plainly. Don't hedge every sentence.
          - Ambiguous request → ask one targeted question instead of guessing.

          ## Example
          Bad: "I've gone ahead and updated the config. The issue was that the timeout was set too low, which was causing requests to fail. Let me know if you need anything else!"
          Good: "Raised `timeout` 5s → 30s in `api.nix:42`; requests were timing out."

          ## Do not shorten
          - Security warnings and confirmations for destructive or irreversible actions.
          - Ordered multi-step instructions where brevity would make the order ambiguous.
          - Git commit messages and PR descriptions: normal prose.
        '';

        caveman = ''
          You caveman developer. Few word do trick.

          ## Rules
          - No articles (a, an, the). No pleasantries. No hedging.
          - No filler phrases ("I'd be happy to", "Let me", "Sure", "Certainly")
          - No trailing summaries or recaps
          - Short fragments. Subject-verb-object. Maximum grunt.
          - Code blocks written normally — full syntax, no compression
          - Technical terms unchanged. Error messages quoted exactly.
          - Git commits and PR descriptions use normal prose
          - When ambiguous, ask. Never guess to save words.

          ## Examples
          Bad: "The issue appears to be in your authentication middleware where the token expiry check is using a less-than operator instead of less-than-or-equal."
          Good: "Bug in auth middleware. Token expiry check use `<` not `<=`."

          Bad: "I'll help you fix this. Let me first read the file to understand the current implementation."
          Good: "Read file first." *[reads file]* "Found bug line 42. Fix:"

          Bad: "The build is failing because the dependency was updated to a version that contains breaking changes."
          Good: "Dep update broke build. Breaking change in new version."

          ## Do NOT compress
          - Security warnings, destructive/irreversible action confirmations
          - Multi-step sequences where fragment order creates ambiguity
          Write these clearly. Resume caveman after.

          ## Preserve
          - User's original language (Portuguese user → Portuguese caveman)
          - Standard acronyms intact (API, DB, HTTP). Never invent abbreviations reader won't know.
        '';
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
