# Personal NixOS Configuration

This is my personal, modular NixOS configuration using Nix Flakes, designed as an example of how to organize and structure a declarative system configuration. It demonstrates patterns for managing multiple hosts and users through abstraction layers.

## 🎯 Key Features

- **Hosts ↔ Roles abstraction** - Separates "what a machine does" (roles) from "which machine it is" (hosts)
- **Users ↔ Profiles abstraction** - Separates user identity from user environment configuration
- **Typed module options** - Roles, profiles, and users are declared as `mkEnableOption` options, giving type-checking and `nix eval` introspection
- **Flake-based configuration** with flake-parts for modularity
- **Home Manager** integration for declarative user-level configurations
- **Impermanence** support with automatic persistence handling
- **Secrets management** - Encrypted secrets with sops-nix for both system and user-level secrets
- **Modular architecture** inspired by nixos-unified autowire concepts

## 📁 Repository Structure

```
.
├── flake.nix              # Main flake configuration
├── lib/                   # Custom utility functions
│   ├── default.nix        # Extends nixpkgs.lib
│   ├── mkDirMap.nix       # Auto-discovery helpers
│   └── mkNixosConfigurations.nix
├── hosts/                 # Host-specific configurations
│   ├── nixos-lt/         # Laptop (default.nix + hardware-config.nix + disko-config.nix)
│   ├── nixos-dt/         # Desktop (default.nix + hardware-config.nix + disko-config.nix)
│   ├── nixos-livecd/     # Live CD / installer image
│   └── nixos-vm/         # Virtual machine configuration
├── packages/              # Custom packages (exported as flake outputs)
│   └── surfshark.nix     # Surfshark VPN client (FHS-wrapped .deb)
├── modules/               # Custom modules
│   ├── flake/            # Flake-specific modules
│   ├── home/             # Home Manager modules (zsh, starship, tmux, etc.)
│   └── nixos/            # NixOS system modules (amd, nvidia, surfshark)
├── roles/                 # System roles — each declares its own option
│   ├── common.nix        # Base system config
│   ├── desktop.nix       # Hyprland, SDDM, Pipewire, Stylix
│   ├── laptop.nix        # Power management
│   ├── impermanent.nix   # Ephemeral root with /persist
│   ├── nfs-client.nix    # NFS automounts
│   ├── gaming.nix        # Steam, Proton, GameMode
│   └── docker.nix        # Docker daemon + k3d DNS
├── profiles/              # User profiles — each declares its own option
│   ├── common.nix        # Essential tools (vim, btop, ghostty, nvim)
│   ├── developer.nix     # Dev tools, git, k8s, direnv
│   ├── desktop-user/     # GUI environment (Hyprland, Waybar, Zen, etc.)
│   │   ├── default.nix   # Packages, scripts, rofi
│   │   ├── hyprland.nix
│   │   ├── waybar.nix
│   │   ├── browser.nix
│   │   ├── lock.nix
│   │   ├── clipboard.nix
│   │   └── themes.nix
│   └── gamer.nix         # MangoHud, Discord
├── users/                 # User-specific configurations
│   └── lucas/
├── secrets/               # Encrypted secrets (sops-nix)
│   ├── shared.yaml
│   ├── ${hostname}.yaml
│   └── users/${username}.yaml
└── overlays/              # Nixpkgs overlays
    ├── overrides.nix      # Package overrides (e.g. freecad boost fix)
    ├── custom-packages.nix # Exposes packages/ into pkgs
    └── patches.nix
```

## 🚀 Using This Configuration

**Note:** This is my personal configuration and is not intended for direct use. Instead, use it as inspiration and reference for organizing your own NixOS configuration.

### Learning from This Repository

This configuration demonstrates several organizational patterns:

1. **Host-Role Separation**: Each host declares which roles it enables; roles define functionality
2. **User-Profile Separation**: Users enable profiles declaratively; profiles define environment config
3. **Typed Options**: Roles and profiles use `mkEnableOption`, so misconfigured names are caught at eval time
4. **Modular Architecture**: Reusable components that can be composed together
5. **Flake Organization**: Using flake-parts and custom lib functions for maintainable flakes

### Example Usage Patterns

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.nixos-lt.config.system.build.toplevel

# Introspect whether a role is enabled on a host
nix eval .#nixosConfigurations.nixos-dt.config.roles.docker.enable

# Test in a VM
nixos-rebuild build-vm --flake .#nixos-vm

# Apply to your own system (after adaptation)
sudo nixos-rebuild switch --flake .#your-hostname
```

## ⚙️ Architecture Explained

### Hosts ↔ Roles Abstraction

**Hosts** define *which* machine this is and *which roles* to enable:
```nix
# hosts/nixos-lt/default.nix
{
  roles = {
    common.enable = true;
    laptop.enable = true;
    desktop.enable = true;
    nfsClient.enable = true;
    impermanent.enable = true;
    gaming.enable = true;
    docker.enable = true;
  };

  hostUsers.lucas.enable = true;
}
```

Hardware-specific settings (boot loader, kernel modules, thermald) live in the host's `hardware-config.nix`, keeping `default.nix` as a clean identity declaration.

**Roles** define *what functionality* a machine should have. Each role declares its own option:
- **common**: Base system config, SSH, nix settings, comin GitOps
- **desktop**: Hyprland with UWSM, SDDM, Pipewire, Stylix theming
- **laptop**: Powertop, thermald, auto-cpufreq
- **impermanent**: Ephemeral root filesystem with `/persist`
- **nfsClient**: NFS automounts per active user
- **gaming**: Steam, Proton-GE, GameMode
- **docker**: Docker daemon, k3d local DNS

This separation means you can:
- Add the `desktop` role to any host to get a full desktop environment
- Create new hosts by combining existing roles
- Modify a role once and have it apply to all hosts using it

### Users ↔ Profiles Abstraction

**Users** define identity and personal settings; **profiles** define the environment:

```nix
# users/lucas/default.nix
{
  profiles = {
    common.enable = true;
    desktopUser.enable = true;
    developer.enable = true;
    gamer.enable = true;
  };
  # Personal git config, SSH settings, GPG, etc.
}
```

**Profiles** define collections of software and settings. Each profile declares its own option:
- **common**: Essential tools, ghostty, btop, nixievim, sops config
- **developer**: Git, direnv, kubectl/helm/talosctl/k9s, lazygit, claude-code
- **desktopUser**: Hyprland, Waybar, Zen Browser, Rofi, cliphist, hypridle
- **gamer**: MangoHud, Discord

### Key Components

#### Desktop Environment (Desktop Role)
- **Hyprland** - Modern Wayland compositor with UWSM support
- **SDDM** - Display manager with astronaut theme
- **Stylix** - System-wide theming with wallpaper-based color schemes
- **Pipewire** - Modern audio system with ALSA, PulseAudio, and JACK support

#### Development Environment (Developer Profile)
- **Git** with histogram diffs, rebase settings, and rerere
- **direnv** with nix-direnv for per-project environments
- **Kubernetes tooling** - kubectl, helm, talosctl, krew, k9s, cilium-cli, fluxcd
- **lazygit** and **lazydocker** for TUI Git/Docker management
- **claude-code**, **jq**, and a broad set of dev utilities

#### Core Tools (Common Profile)
- **Nixievim** - Custom Neovim distribution built with nixvim
- **Ghostty** - Terminal emulator
- **Starship** prompt and **Zsh** shell
- **Home Manager** - Declarative user configuration management
- **Btop** - System monitor
- **sops-nix** - User secret decryption via YubiKey GPG

## 🔐 Secrets Management

This configuration uses **sops-nix** for encrypted secrets management, supporting both system-level and user-level secrets.

### Architecture

**System Secrets**: Managed in the `common` role, decrypted at boot via the SSH host key (age):
- `secrets/shared.yaml` - Shared across all hosts
- `secrets/${hostname}.yaml` - Host-specific secrets (e.g., `nixos-lt.yaml`)

**User Secrets**: Managed in user profiles, decrypted by the user's GPG key (YubiKey):
- `secrets/users/${username}.yaml` - User-specific secrets

### Configuration Files

**`.sops.yaml`** - Defines encryption keys and access rules:
```yaml
keys:
  - &nixos-lt age1k2m2hjlr26pgxvtuesw6wpgxv5kx5je5egck9r3x7rujteh0a3hqypwxry
  - &nixos-dt age1epjrwdd07pzzkzjvcd9epln3tvjzlayjllxfpj4nqtf4qjsjcf6qgvx0xz
  - &lucas-gpg 1818334CEAC35348ED5E30F5DD40CEDB2EEAD4A4  # YubiKey GPG key

creation_rules:
  - path_regex: secrets/nixos-lt\.yaml$
    key_groups:
      - age: [*nixos-lt]
        pgp: [*lucas-gpg]
  - path_regex: secrets/shared\.yaml$
    key_groups:
      - age: [*nixos-lt, *nixos-dt]
        pgp: [*lucas-gpg]
  - path_regex: secrets/users/lucas\.yaml$
    key_groups:
      - age: [*nixos-lt, *nixos-dt]
        pgp: [*lucas-gpg]
```

### Key Management

**System Keys**: Derived from SSH host keys (age) — imported automatically during `nixos-rebuild`
```bash
# Located at: /persist/etc/ssh/ssh_host_ed25519_key  (impermanent hosts)
#             /etc/ssh/ssh_host_ed25519_key           (other hosts)
```

**User/Admin Key**: GPG key stored on YubiKey — plug in the YubiKey and GPG agent handles decryption automatically

### Usage Examples

**Creating System Secrets**:
```bash
sops secrets/nixos-lt.yaml
sops secrets/shared.yaml
```

**Creating User Secrets**:
```bash
sops secrets/users/lucas.yaml
```

**Declaring Secrets in Configuration**:

System secrets (in roles/common.nix):
```nix
sops.secrets = {
  shared-secret = {
    sopsFile = secretsPath + "/shared.yaml";
  };
  host-secret = {}; # Uses defaultSopsFile
};
```

User secrets (in profiles/common.nix):
```nix
sops.secrets = {
  user-secret = {}; # Uses defaultSopsFile (users/${username}.yaml)
};
```

### Security Model

- System secrets decrypted at boot via the SSH host key (no user interaction)
- User secrets decrypted on demand via YubiKey GPG (requires physical touch)
- Proper file permissions (0400) for all secret files
- Impermanence: `/etc/ssh` persisted so the host key survives reboots

## 🔧 Customization

### Bootstrapping a New Host

#### 1 — Add the host config

Create `hosts/<hostname>/default.nix` and `hosts/<hostname>/disko-config.nix`. See `hosts/nixos-lt/` for a reference.

```nix
# hosts/<hostname>/default.nix
{config, lib, ...}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  system.stateVersion = "25.11";

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  roles = {
    common.enable = true;
    desktop.enable = true;
    impermanent.enable = true;
  };

  hostUsers.alice.enable = true;
}
```

#### 2 — Add a placeholder sops key

Add a placeholder age key under `keys:` in `.sops.yaml` and add the appropriate `creation_rules` entry. The real key is derived from the SSH host key after first boot.

```bash
sops secrets/<hostname>.yaml
```

Commit and push so comin can pull the config on first boot.

#### 3 — Install

Boot from the [livecd](hosts/nixos-livecd/) image, clone the repo, then:

```bash
sudo disko --mode disko hosts/<hostname>/disko-config.nix
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/<hostname>/hardware-config.nix
sudo nixos-install --flake .#<hostname>
```

#### 4 — Wire up sops after first boot

```bash
# On the new host
ssh-to-age < /persist/etc/ssh/ssh_host_ed25519_key.pub

# On your dev machine (YubiKey required)
# Replace the placeholder in .sops.yaml, then re-encrypt
sops updatekeys secrets/shared.yaml
sops updatekeys secrets/users/lucas.yaml
git add .sops.yaml secrets/
git commit -m "chore(sops): add <hostname> host key"
git push
```

comin will pick up the changes automatically.

### Adding New Roles

Create a new file in `roles/`. The file auto-discovers via `mkDirMap` — no manual imports needed.

```nix
# roles/my-role.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.roles.myRole.enable = lib.mkEnableOption "description of what this role does";

  config = lib.mkIf config.roles.myRole.enable {
    # Role-specific NixOS configuration
  };
}
```

Enable it on a host:
```nix
# hosts/<hostname>/default.nix
roles.myRole.enable = true;
```

### Adding New Profiles

Create a new file in `profiles/`. Same auto-discovery applies.

```nix
# profiles/my-profile.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.profiles.myProfile.enable = lib.mkEnableOption "description of this profile";

  config = lib.mkIf config.profiles.myProfile.enable {
    # Home Manager configuration
  };
}
```

Enable it for a user:
```nix
# users/<username>/default.nix
profiles.myProfile.enable = true;
```

### User Configuration

User configurations live in `users/<username>/default.nix`. Each user specifies:
- Which profiles to enable
- Personal identity (git, SSH, GPG)
- Personal packages
- Persistent files and folders (for impermanence)
- SOPS secrets

## 🔄 Maintenance

### Updating Dependencies
```bash
nix flake update
sudo nixos-rebuild switch --flake .#<hostname>
```

### Cleaning Old Generations
```bash
sudo nix-collect-garbage -d
```

### Formatting Code
```bash
nix fmt
```

## 🏗️ Architecture

This configuration uses a modular architecture:

1. **Flake-parts** for organizing flake outputs
2. **`lib/`** — custom utilities split across focused files (`mkDirMap`, `mkNixosConfigurations`)
3. **Role-based system** — each role is a self-contained module with its own `mkEnableOption`
4. **Profile-based user management** — same pattern for home-manager profiles
5. **Host-specific overrides** — `default.nix` for identity, `hardware-config.nix` for hardware

The `lib/mkDirMap.nix` utility auto-discovers all `.nix` files in `hosts/`, `roles/`, `profiles/`, `users/`, and `modules/` — adding a new role or profile is as simple as creating the file.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) for the amazing operating system
- [Home Manager](https://github.com/nix-community/home-manager) for user configuration management
- [Stylix](https://github.com/nix-community/stylix) for system theming
- [Hyprland](https://hyprland.org/) for the beautiful desktop environment
- [Impermanence](https://github.com/nix-community/impermanence) for stateless system support
