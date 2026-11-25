# AGENTS.md

NixOS + Home Manager flake built on omninix. Read `README.md` first: it has the
machines, the layout and how hosts, roles, users and profiles fit together.

## Rules

- **Declarative only.** Every change goes through this flake. Never `nix profile install`,
  `nix-env`, `nix store add`, `nix-channel` or hand-edits under `/etc` or `~/.config`.
- **Never commit or push.** Leave changes staged; the owner reviews and commits.
- **Secrets:** `secrets/*.yaml` are sops-encrypted. Never edit them directly or print
  decrypted values; changes go through `sops`. Never put credentials in `.nix` files:
  anything in the store is world-readable.
- **`flake.lock`** changes only via `nix flake lock` / `nix flake update <input>`.
- User identity (name, email, keys) lives in `users/<name>/`, never in shared roles,
  profiles or modules. Public keys go in `users/<name>/pubkeys.nix`.

## Conventions

- Auto-discovery: a module is `<name>.nix` or `<name>/default.nix`; adding the file is
  enough. A file and a folder with the same name is an error.
- `internal/` folders hold flake-specific modules that aren't exported.
- Format with `nix fmt` (alejandra). Comments are one line, saying why, not what.
- Scripts installed with `executable = true` still need `chmod +x` in the repo;
  Home Manager keeps the source file's mode.
- Hyprland 0.57+ reads only the Lua config (`configType = "lua"`); `hyprland.conf` is
  ignored. Check with `hyprctl --verify-config`.
- Commits: Conventional Commits with the area as scope, e.g. `feat(hyprland): …`,
  `fix(desktop): …`, `chore(flake): bump nixievim`.

## Verify before handing back

Same checks as CI (`.github/workflows/check-flakes.yaml`):

```sh
nix fmt -- --check .
nix flake check
for h in nixos-lt nixos-dt nixos-vm nixos-wsl; do
  nix eval --raw ".#nixosConfigurations.$h.config.system.build.toplevel.drvPath"
done
nix eval --raw .#homeConfigurations.lucas.activationPackage.drvPath
```

For a refactor, build `home-files` (or `toplevel`) before and after and diff the
outputs; a pure refactor should change nothing except store paths that embed the
flake source (e.g. wallpapers).

Nix builds need the nix daemon, so in a sandboxed agent shell run them unsandboxed.
