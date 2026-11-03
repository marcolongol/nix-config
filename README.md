# nix-config

My NixOS machines and Home Manager setup, as one flake. It's built on
[omninix](https://github.com/marcolongol/omninix), which discovers the directories
below and wires hosts, users, secrets and impermanence together.

It's a personal config, not a template. Borrow whatever patterns are useful. For a
starting point of your own, use `nix flake init -t github:marcolongol/omninix`.

## Machines

| Host | What it is | Roles |
|---|---|---|
| `nixos-lt` | Laptop | common, laptop, desktop, gaming, docker, nfsClient, impermanent (with root wipe) |
| `nixos-dt` | Desktop | common, desktop, gaming, docker, nfsClient, impermanent (with root wipe) |
| `nixos-vm` | Throwaway VM for testing | common, desktop, nfsClient |
| `nixos-wsl` | WSL distro, stock `nixos` user, no Home Manager | common |

Home Manager also builds standalone for non-NixOS machines:
`home-manager switch --flake .#lucas`.

## Layout

```
flake.nix          inputs + flake-parts with omninix.flakeModules.default
hosts/<name>/      one machine: roles, users, monitors, hardware, disko
roles/             what a machine does (system side, some with a home side)
users/lucas/       who I am: profiles, git/ssh/gpg, personal secrets, pubkeys.nix
profiles/          what a user gets (common, developer, worker)
modules/nixos/     imported into every host (drivers, services)
modules/nixos/internal/  this flake only: identity
modules/home/      imported for every user (zsh, starship, tmux, languages)
modules/home/internal/   this flake only: claude-code
packages/          own packages, available as pkgs.<name> (surfshark, harmony-sase)
overlays/          nixpkgs overrides (overrides.nix)
secrets/           sops files: shared.yaml, <host>.yaml, users/<user>.yaml
wallpapers/        stylix wallpapers
```

Every `.nix` file in these directories is picked up automatically. Adding a role,
profile, package or overlay means adding the file, nothing else. Files under an
`internal/` folder are used here but not exported for other flakes: they read this
flake's inputs or hold values specific to these machines. Third-party modules (disko,
impermanence, stylix, comin, nix-index, nixievim, zen) are listed once in `flake.nix`
as `extraNixosModules` / `extraHomeManagerModules`.

## How it fits together

**Hosts pick roles and users:**

```nix
# hosts/nixos-lt/default.nix
{
  roles = {
    common.enable = true;
    laptop.enable = true;
    desktop.enable = true;
    impermanent = {
      enable = true;
      wipe = {
        enable = true;
        acknowledgeDataLoss = true;
      };
    };
  };

  omninix.hostUsers.lucas = {
    enable = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
  };
}
```

**Users pick profiles:**

```nix
# users/lucas/default.nix
{
  profiles = {
    common.enable = true;
    developer.enable = true;
  };
}
```

Each role and profile declares its own `enable` option, so a typo fails the build and
`nix eval .#nixosConfigurations.nixos-dt.config.roles.docker.enable` tells you what's
on.

**Roles with a user side.** `desktop` and `gaming` ship their Home Manager half
through `home-manager.sharedModules`. Enabling the role on a host gives every user on
it Waybar, Rofi, MangoHud and so on. There's no matching profile to keep in sync.

### Roles

| Role | What it does |
|---|---|
| `common` | base system: nix settings, SSH, networking, comin GitOps, shared secrets |
| `desktop` | Hyprland (UWSM), SDDM, Pipewire, Stylix; home side: Waybar, Rofi, Zen, scripts |
| `laptop` | power management |
| `gaming` | Steam, Proton-GE, GameMode; home side: MangoHud, Discord |
| `docker` | Docker daemon, k3d local DNS |
| `nfsClient` | NFS automounts per active user |
| `impermanent` | omninix's shipped role: `/persist` plus a btrfs root wipe on every boot |

### Profiles

| Profile | What it does |
|---|---|
| `common` | everyday tools: nixievim, ghostty, btop, user sops |
| `developer` | git, direnv, Kubernetes tooling, lazygit/lazydocker, claude-code |
| `worker` | work apps (Remmina, Webex, LibreOffice, …) |

## Secrets 🔐

sops-nix, wired by omninix from `secrets/`:

| File | Decrypted by | Holds |
|---|---|---|
| `secrets/shared.yaml` | every host (SSH host key, as age) | secrets all hosts need |
| `secrets/<host>.yaml` | that host | the host's own secrets (its default sops file) |
| `secrets/users/lucas.yaml` | every host, and me (YubiKey GPG) | my login password (`hashed-password`), plus Home Manager secrets |

Who can decrypt what is in [`.sops.yaml`](.sops.yaml). Home Manager secrets decrypt
at login through the YubiKey. Without the key plugged in they stay empty until
`systemctl --user start sops-nix.service`.

Login also accepts the YubiKey's SSH key through `pam_ssh_agent_auth`
(`modules/nixos/internal/identity.nix`); the password is the fallback. Users are immutable
(`users.mutableUsers = false`) on every host with repo users.

## Impermanence

`nixos-lt` and `nixos-dt` throw away their root on every boot. Only what's in
`/persist` survives. Anything that needs to stick is declared next to the config that
uses it:

```nix
omninix.persistence.directories = [".config/remmina"]; # in a user or profile
omninix.persistence.directories = ["/var/lib/docker"]; # in a host or role
```

How the wipe works, its safety checks, and live-USB recovery:
[omninix docs/impermanence.md](https://github.com/marcolongol/omninix/blob/main/docs/impermanence.md).

## Adding a machine

1. **Host config.** Create `hosts/<name>/default.nix` plus `disko-config.nix`,
   copying from `nixos-lt`. Start **without** `impermanent.wipe`.
2. **Secrets.** Add a placeholder age key and a `creation_rules` entry for the host in
   `.sops.yaml`, then create `secrets/<name>.yaml` with `sops`. Commit and push so
   comin can pull on first boot.
3. **Install** from a NixOS ISO:
   ```bash
   sudo disko --mode disko hosts/<name>/disko-config.nix
   sudo nixos-generate-config --no-filesystems --root /mnt
   cp /mnt/etc/nixos/hardware-configuration.nix hosts/<name>/hardware-config.nix
   sudo nixos-install --flake .#<name>
   ```
4. **Real host key.** On the new host run `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`.
   Then, on a machine with the YubiKey:
   - put that key in `.sops.yaml` in place of the placeholder;
   - run `sops updatekeys` on `shared.yaml`, `<name>.yaml` and `users/lucas.yaml`;
   - commit and push.
5. **Then the wipe.** Copy the SSH host keys and `/etc/machine-id` into `/persist`,
   reboot once to check, then enable `impermanent.wipe`. Follow the
   [staged rollout](https://github.com/marcolongol/omninix/blob/main/docs/impermanence.md#%EF%B8%8F-rolling-it-out-on-an-existing-machine).
   ⚠️ Enabling the wipe before the host key is in `/persist` locks you out: sops can't
   decrypt the password.

## Day to day

```bash
nh os switch .                  # apply locally
nix flake check                 # what CI runs, plus `nix fmt -- --check .`
nix fmt                         # alejandra
nixos-rebuild build-vm --flake .#nixos-vm
```

- **Deploys:** comin on each host pulls `main` and switches by itself.
- **Updates:** Renovate opens PRs for flake inputs. Single-input bumps automerge.
  Lock maintenance, major updates, omninix and flake-parts wait for review.
- **CI:** checks the flake and formatting, evaluates the standalone Home Manager
  config, and builds the WSL tarball.
