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
