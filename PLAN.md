# PLAN: migrate nix-config onto omninix

> Execution rule: **one phase at a time. Each phase ends at a GATE. Nothing from the next phase starts until Lucas reviews the gate evidence and explicitly approves.**

## Context

nix-config carries its own mini-framework (`lib/mkDirMap.nix`, `lib/mkNixosConfigurations.nix`, `hostUsers`, `persistentFolders/Files`, per-user HM wiring in `modules/nixos/default.nix`). `../omninix` is the generalized, tested version of the same idea (discovery, builders, `omninix.hostUsers`, `omninix.persistence.*` with an automatic HM impermanence bridge, fail-closed passwords, sops wiring). Goal: consume omninix via `mkFlake` (Path A), delete the local framework, keep behavior identical, and gain a standalone `homeConfigurations.lucas`.

A 3-agent review (architect, reviewer with a throwaway prototype, security-auditor) on 2026-10-30 confirmed parity is achievable: all 5 hosts evaluate under omninix; groups, keys, password file, mutableUsers, sudo, PAM, sops secrets, system + HM persistence, and package sets are identical. Toplevel drvPaths change only by list ordering in the swap step. Raw reports: session scratchpad `architect-plan.md`, `reviewer-findings.md`, `security-findings.md`, prototype `proto/` + `proto-baseline/migration.patch`.

### Known risks driving the gate design
- **Critical, latent:** `roles/common.nix:163` `wheelNeedsPassword = mkDefault false`; the only `true` lives behind the old `hostUsers` gate (`modules/nixos/default.nix:72`). Miss it in the swap → passwordless sudo on dt/lt/vm.
- **comin deploys `main` to every host**, renovate automerges lock updates → a bad merge hits all machines at once.
- **Data loss** if any persistence path drops on impermanent hosts (dt, lt).
- **omninix is private** → comin, CI, livecd install and even `nix flake lock` can't fetch it.
- `homeConfigurations.lucas` breaks (`attribute 'stylix' missing`, `modules/home/starship.nix:2`) and `nix flake check` does not catch it.

### Working rules (all phases)
- Work on branch `omninix-migration`; one commit per step; **never merge to `main` before Phase 8.**
- `nix flake lock` only, never `update` (a nixpkgs bump invalidates every comparison).
- nix commands run outside the Claude sandbox (sandbox blocks the daemon socket and plants a locked `.gitmodules`).
- No `nixos-rebuild switch`, no push, no merge without explicit approval at a gate.
- Baseline rev: `9708c80` (current `main`).

### Verification helpers (defined once, reused at every gate)
```bash
BASE="git+file://$PWD?rev=9708c80e223759ec4d632cfff482d68f1b63de37"
HOSTS="nixos-dt nixos-lt nixos-vm nixos-wsl nixos-livecd"
drvs()    # toplevel drvPath per host
summ()    # semantic summary per host: mutableUsers, wheelNeedsPassword, groups, keys, pwFile,
          # sops secrets, age key paths, PAM sshAgentAuth services, system+HM persistence, pkg names
semdiff() # summ BASE vs . for all hosts → OK/DIFF
sops_sig()# hash of setupSecrets + setupSecretsForUsers activation text
```
Full definitions are in `architect-plan.md` §3 (tested against baseline); copy them into `scripts/migration-check.sh` in Phase 1 so every gate runs the same thing.

---

## Phase 0 — Decisions and prep (no code)

Decide (recommendation first):
1. **omninix access** (outward-facing; needs your explicit approval):
   - **(A) Publish** ← recommended. History scan of all 4 commits found no secrets; remove the tracked `result` symlink first. Hard to undo once public.
   - **(B) Stay private** with a read-only single-repo deploy key / fine-grained PAT, delivered by sops to a root-only file loaded via `nix.extraOptions = "!include <path>"`. **Never** `nix.settings.access-tokens` (lands world-readable in the store and `/etc/nix/nix.conf`). Adds a credential per host; vm/wsl have no age key to decrypt it; CI needs its own token.
   - **(C) Vendor** into nix-config (subtree + relative path input).
2. **Standalone `homeConfigurations.lucas`:** needed on some non-NixOS box? If no, Phase 7 is skipped.
3. **Groups:** `omninix.defaultUserGroups` (exact parity) ← recommended for the migration; per-user `extraGroups` as a later cleanup.
4. **Starship in standalone:** `config.lib.stylix.colors or <fallback>` (keeps NixOS drvs identical) ← recommended / move to desktop role home side.
5. **`systems` input:** declare explicitly as `github:nix-systems/default/future-26.11` (matches current lock) ← recommended.
6. **Third-party module wrapper:** one `modules/nixos/inputs.nix` (parity) ← recommended; impermanence must stay fleet-wide either way.

Prep actions (Lucas):
- Pause renovate automerge (`.github/renovate.json5` `lockFileMaintenance.automerge` + digest rule) for the migration window.
- Permanently exclude the `omninix` input from renovate automerge (a new root-trust input auto-deployed by comin).

**Decisions (2026-10-31):**
1. omninix access → **published** (public, verified API 200; history squashed to `37fd7b7`). Tracked `result` symlink still present → removed in Phase 2.
2. Standalone HM → **yes**, Phase 7 stays.
3. Groups → **per-user `omninix.hostUsers.lucas.extraGroups`** (not `defaultUserGroups`). dt/lt: `wheel networkmanager plugdev docker`; vm: `wheel networkmanager plugdev`. Drop the docker-role group append (a role can't append to `omninix.hostUsers.*` without recursion); Gate 5 checks the group *set* still equals baseline per host.
4. Starship → stylix fallback (default).
5. `systems` → `github:nix-systems/default/future-26.11`.
6. One `modules/nixos/inputs.nix` wrapper.

**GATE 0:** decisions recorded in this file; automerge paused.

---

## Phase 1 — Security pre-fix on `main` (independent, safe alone)

- Delete `roles/common.nix:162-163` (comment + `security.sudo.wheelNeedsPassword = lib.mkDefault false;`). NixOS default `true` then applies on dt/lt/vm; wsl and livecd keep their upstream `false` (NixOS-WSL `mkDefault false`, installer override). **Do not** set a plain `true` (would break WSL's passwordless `nixos` user).
- Deleting `:163` alone removes the risk: nothing sets the option, so the NixOS default `true` holds even if a later refactor drops the identity `true` line (reviewer variant v6r).
- Add guard assertion in `roles/common.nix` (not identity.nix, so it survives that module being dropped): `activeUsers == [] || config.security.sudo.wheelNeedsPassword`, message `security.sudo.wheelNeedsPassword must be true on hosts with active users`. Reads today's `hostUsers` (exists until the swap, so the trap is covered *before* the risky phase); Phase 6 rewrites it to `!(lib.any (u: u.enable) (lib.attrValues config.omninix.hostUsers)) || …`. The architect's plan adds it at the swap instead — equivalent end state. Verified: passes on all 5 hosts, fails closed on dt/lt/vm if an explicit `false` returns (v6, v6r2).
- Add `scripts/migration-check.sh` with the helpers (not imported by any module).

Verify: `drvs .` identical to base on all 5 hosts (reviewer variant v5b proved it); `summ` shows `sudoPw = true` on dt/lt/vm.

**GATE 1:** Lucas reviews diff + drv evidence; decides whether this lands on `main` now (recommended: yes, it removes the trap regardless of migration).

---

## Phase 2 — omninix upstream prep (in `../omninix`)

- Fix password-check gap M1: treat `""` (`password`/`initialPassword`/`hashedPassword` empty) as no password; check the user's `hashedPasswordFile` is actually set, not just that the secret file exists. Add tests in `tests/config-tests.nix`.
- Guard the HM impermanence bridge with `options ? home.persistence` (lets impermanence be scoped later; non-blocking).
- Commit the roles-with-home-side template/README/tests already in the working tree.
- Template `roles/impermanent.nix`: replace the silent `inputs ? impermanence` guard with an assertion (enabled role without the input must fail eval, not no-op).
- Apply the Phase 0 access decision (e.g. flip repo public).

Note: the M1 fix makes nixos-vm (`initialPassword = ""`) fail the assertion → nixos-vm needs `omninix.allowInsecureBootstrap = true` or a real hashed password in Phase 5. Decide at this gate.

Verify: `FAST=1 bash tests/run-all-tests.sh` passes; `nix flake metadata github:marcolongol/omninix` works unauthenticated (or with chosen token path) as root and from CI.

**GATE 2:** omninix rev to pin is fixed; fetch works for comin/CI.

---

## Phase 3 — Inputs + drop own-lib from overlays/packages (drvPath-identical)

- `flake.nix`: declare `systems.url = "github:nix-systems/default/future-26.11"`; add `omninix` input with `follows` for nixpkgs, flake-parts, home-manager, sops-nix, systems. `nix flake lock`.
- `overlays/default.nix` → exports a **list** of one overlay using `prev.lib` + builtins (no external `lib`; `final.lib` causes infinite recursion). Validated rewrite in `architect-plan.md` Step 2.
- `lib/mkNixosConfigurations.nix` and `modules/flake/default.nix` perSystem: `overlays = import ../overlays;`.
- `packages/default.nix:8`: `flake.inputs.omninix.lib.omninix.forAllNixFiles`.

Verify: `git diff flake.lock` adds only omninix (+ systems decl, same rev); `drvs .` == base; `pkgs.surfshark`/`harmony-sase` drvPaths == base.

**GATE 3.**

---

## Phase 4 — Extract `modules/nixos/identity.nix` (drvPath-identical)

Move from `modules/nixos/default.nix` into `identity.nix`, gated `mkIf (activeUsers != [])`, still reading old `config.hostUsers`:
- `users.mutableUsers = false` (gated — wsl/livecd stay `true` as today),
- authorized keys from `users/<name>/pubkeys.nix`, PAM `sshAgentAuth` (login/sudo/hyprlock/sddm), `wheelNeedsPassword = true` (belt-and-braces; the Phase 1 assertion stays in `roles/common.nix`).

Verify: `drvs .` == base (fallback: `semdiff` all OK).

**GATE 4.**

---

## Phase 5 — The swap (single commit; order-only drift expected)

- `modules/flake/default.nix`: `flake = inputs.omninix.lib.omninix.mkFlake inputs { hostsDir rolesDir usersDir profilesDir nixosModulesDir homeManagerModulesDir overlaysDir secretsPath; allowUnfree = true; };` — **no** `packagesDir`, `extraRoles`, `extraProfiles`. perSystem (formatter, packages incl. livecd-iso) unchanged.
- Delete `lib/` (3 files), `modules/nixos/default.nix`, `modules/home/default.nix` (omninix would auto-import them as `default`).
- Add temporary `modules/nixos/compat.nix` / `modules/home/compat.nix` — must be **true aliases** (`mkAliasOptionModule`/`mkRenamedOptionModule`), never a separate shadow option (would recreate the silent-empty `hostUsers` trap): for `hostUsers`, `persistentFolders`, `persistentFiles` → `omninix.*`.
- Add `modules/nixos/inputs.nix`: disko, impermanence (fleet-wide and **unconditional** — no `inputs ? impermanence` guard like the omninix template; a silently skipped import with a wiped root regenerates host keys every boot → sops can't decrypt → lockout), stylix, comin, nix-index. zen-browser HM module imported in `roles/desktop/home/browser.nix`.
- Groups per Decision 3: `omninix.hostUsers.lucas.extraGroups` in each host file (hosts/nixos-{dt,lt,vm}); remove the old group logic from `modules/nixos/default.nix` (`roles.docker` conditional).
- `profiles/common.nix`: drop `osConfig` + `home.persistence` block; 7 base dirs → `persistentFolders` (alias). **Must be same commit** (else impermanence duplicate-path assertion).
- `roles/common.nix:165-175`: delete `age.sshKeyPaths`, `defaultSopsFormat`, `defaultSopsFile`; keep `secrets.shared-secret`.
- nixos-vm per Gate 2 decision.

Verify:
- all 5 hosts evaluate; `semdiff` all OK; `diff <(sops_sig $BASE) <(sops_sig .)` empty;
- generated-file diff vs base build (`9708c80`) for **nixos-lt and nixos-dt** (option parity ≠ file parity): sudoers, `/etc/pam.d/{sudo,login,hyprlock,sddm}`, sshd_config, `/etc/ssh/authorized_keys.d/lucas`, users-groups.json, both sops manifests. Only acceptable diff: none (dup sshKeyPaths already removed this phase);
- `nixos-rebuild build --flake .#nixos-lt` + `nvd diff result-base result` → no package/version changes;
- `nix flake check --no-build`.

**GATE 5 (highest risk):** Lucas reviews full semantic + security diff before anything else.

---

## Phase 6 — Rename sweep + drop shims (drvPath-identical to Phase 5)

`persistentFolders/Files` → `omninix.persistence.directories/files`, `hostUsers` → `omninix.hostUsers` at every site (hosts, roles/common assertion, roles/laptop, roles/nfs-client, roles/desktop, roles/docker, roles/impermanent, modules/nixos/amd, modules/home/*, profiles/*, users/lucas); delete both compat.nix.

Verify: `drvs .` == Phase 5; `rg -n 'persistentFolders|persistentFiles|\bhostUsers' -g '*.nix' | rg -v omninix` empty.

**GATE 6.**

---

## Phase 7 — Standalone HM (skip if Gate 0 says not needed)

`modules/home/starship.nix:2` → stylix fallback. Add an explicit check (script + CI step) for `homeConfigurations.lucas.activationPackage`, since `flake check` misses it.

Verify: `nix build --no-link .#homeConfigurations.lucas.activationPackage`; `drvs .` == Phase 6.
Known gaps by design: no role home sides, no persistence, sops needs YubiKey GPG.

**GATE 7.**

---

## Phase 8 — Canary rollout and merge (on-machine, Lucas present)

1. Push branch to `testing-nixos-lt` (comin applies with operation `test`: no boot entry, reboot reverts) — or `sudo nixos-rebuild test --flake .#nixos-lt` locally.
2. On lt with a root TTY + an SSH session open: sudo with and without YubiKey, hyprlock unlock, SDDM login, sops secrets present in `/run/secrets`, `/persist` mounts intact, HM services up.
3. `nixos-rebuild boot` + reboot on lt; repeat checks. Rollback = previous systemd-boot entry.
4. Repeat 1–3 for nixos-dt. vm/wsl: eval-only smoke (vm is not a faithful canary).
5. Merge `omninix-migration` → `main`; watch comin on all hosts; re-enable renovate automerge.

**GATE 8:** each host checked off by Lucas before the merge.

---

## Phase 9 — Cleanup + docs

- Remove `flake.nix:88` (`_module.args.inputs`) and `:92` (`self` output).
- Update README (structure, omninix usage, roles-with-home-side), memory notes that reference `hostUsers`/`persistentFolders`.
- Optional: scope disko/stylix/comin into roles.
- Delete `PLAN.md` and `scripts/migration-check.sh` (or keep the script as CI).

**GATE 9:** done.

---

## Out of scope (pre-existing, carried unchanged)
YubiKey-touch-only sudo/screen unlock; Harmony SASE NOPASSWD root helper for all accounts; surfshark iptables wrapper writable by any user. Track separately.
