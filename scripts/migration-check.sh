#!/usr/bin/env bash
# Gate checks for the omninix migration (PLAN.md). Compares the working tree against BASE.
# Usage: scripts/migration-check.sh {drvs|semdiff|summ <host>|sops|all}
set -euo pipefail

BASE="${BASE:-git+file://$PWD?rev=9708c80e223759ec4d632cfff482d68f1b63de37}"
HOSTS="${HOSTS:-nixos-dt nixos-lt nixos-vm nixos-wsl nixos-livecd}"

# Wallpaper comes from inputs.self, so every commit changes desktop drvs; pin it to BASE's.
drvs() {
  local ref="$1"
  [ "$ref" = . ] && ref="git+file://$PWD"
  for h in $HOSTS; do
    echo "$h $(nix eval --raw --impure --expr "
      let
        base = (builtins.getFlake \"$BASE\").nixosConfigurations.$h.config.stylix;
        sys = (builtins.getFlake \"$ref\").nixosConfigurations.$h;
        pinned = sys.extendModules {
          modules = [({lib, ...}: lib.optionalAttrs base.enable { stylix.image = lib.mkForce base.image; })];
        };
      in pinned.config.system.build.toplevel.drvPath")"
  done
}

summ() {
  nix eval --json "$1#nixosConfigurations.$2.config" --apply '
    c: let
      s = builtins.sort builtins.lessThan;
      n = p: p.name or "?";
      d = x: if builtins.isString x then x else x.directory or x.file or "?";
      hm = c.home-manager.users.lucas or null;
      per = c.environment.persistence."/persist" or null;
    in {
      mutable = c.users.mutableUsers;
      sudoPw = c.security.sudo.wheelNeedsPassword;
      host = c.networking.hostName;
      groups = if c.users.users ? lucas then s c.users.users.lucas.extraGroups else null;
      keys = c.users.users.lucas.openssh.authorizedKeys.keys or null;
      pwFile = c.users.users.lucas.hashedPasswordFile or null;
      secrets = s (builtins.attrNames c.sops.secrets);
      ageKeys = map toString c.sops.age.sshKeyPaths;
      pam = s (builtins.filter (k: c.security.pam.services.${k}.sshAgentAuth or false) (builtins.attrNames c.security.pam.services));
      sysPersist = if per == null then null else s (map d (per.directories ++ per.files));
      hmPersist = if hm == null then null else s (map d ((hm.home.persistence."/persist".directories or []) ++ (hm.home.persistence."/persist".files or [])));
      sysPkgs = s (map n c.environment.systemPackages);
      hmPkgs = if hm == null then null else s (map n hm.home.packages);
    }' | jq -S .
}

semdiff() {
  local rc=0
  for h in $HOSTS; do
    if diff <(summ "$BASE" "$h") <(summ . "$h") >/dev/null; then echo "$h OK"; else echo "$h DIFF"; rc=1; fi
  done
  return $rc
}

sops_sig() {
  for h in $HOSTS; do
    echo "$h $(nix eval --json "$1#nixosConfigurations.$h.config.system.activationScripts" \
      --apply 'a: [(a.setupSecrets.text or "") (a.setupSecretsForUsers.text or "")]' | sha256sum | cut -c1-12)"
  done
}

case "${1:-all}" in
  drvs) diff <(drvs "$BASE") <(drvs .) && echo "drvs identical" ;;
  semdiff) semdiff ;;
  summ) summ . "$2" ;;
  sops) diff <(sops_sig "$BASE") <(sops_sig .) && echo "sops identical" ;;
  all)
    diff <(drvs "$BASE") <(drvs .) && echo "drvs identical" || echo "drvs differ"
    semdiff
    diff <(sops_sig "$BASE") <(sops_sig .) && echo "sops identical"
    ;;
  *) echo "usage: $0 {drvs|semdiff|summ <host>|sops|all}" >&2; exit 2 ;;
esac
