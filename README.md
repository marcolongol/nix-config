# Personal NixOS Configuration

This is my personal, modular NixOS configuration using Nix Flakes, designed as an example of how to organize and structure a declarative system configuration. It demonstrates patterns for managing multiple hosts and users through abstraction layers.

## 🎯 Key Features

- **Hosts ↔ Roles abstraction** - Separates "what a machine does" (roles) from "which machine it is" (hosts)
- **Users ↔ Profiles abstraction** - Separates user identity from user environment configuration  
- **Multiple user support** - Each user can have different profiles and configurations
- **Flake-based configuration** with flake-parts for modularity
- **Home Manager** integration for declarative user-level configurations
- **Impermanence** support with automatic persistence handling
- **Secrets management** - Encrypted secrets with sops-nix for both system and user-level secrets
- **Modular architecture** inspired by nixos-unified autowire concepts

## 📁 Repository Structure

```
.
├── flake.nix              # Main flake configuration
├── lib.nix                # Custom utility functions
├── hosts/                 # Host-specific configurations
│   ├── nixos-lt/         # Laptop configuration
│   ├── nixos-dt/         # Desktop configuration
│   ├── nixos-livecd/     # Live CD / installer image
│   └── nixos-vm/         # Virtual machine configuration
├── modules/               # Custom modules
│   ├── flake/            # Flake-specific modules
│   ├── home/             # Home Manager modules
│   └── nixos/            # NixOS system modules
├── roles/                 # System roles (common, desktop, laptop, etc.)
├── profiles/              # User profiles (common, developer, desktop-user)
├── users/                 # User-specific configurations
│   └── lucas/            # User: Lucas configurations
├── secrets/               # Encrypted secrets management
│   ├── shared.yaml       # System-wide shared secrets
│   ├── ${hostname}.yaml  # Host-specific system secrets
│   └── users/            # User-specific secrets
│       └── ${username}.yaml
└── overlays/              # Nixpkgs overlays
```

## 🚀 Using This Configuration

**Note:** This is my personal configuration and is not intended for direct use. Instead, use it as inspiration and reference for organizing your own NixOS configuration.

### Learning from This Repository

This configuration demonstrates several organizational patterns:

1. **Host-Role Separation**: Each host defines which roles it needs, roles define functionality
2. **User-Profile Separation**: Users can mix and match profiles for different environments
3. **Modular Architecture**: Reusable components that can be composed together
4. **Flake Organization**: Using flake-parts and custom lib functions for maintainable flakes

### Example Usage Patterns

```bash
# Build a specific host configuration
nix build .#nixosConfigurations.nixos-lt.config.system.build.toplevel

# Test in a VM
nixos-rebuild build-vm --flake .#nixos-vm

# Apply to your own system (after adaptation)
sudo nixos-rebuild switch --flake .#your-hostname
```

## ⚙️ Architecture Explained

### Hosts ↔ Roles Abstraction

**Hosts** define *which* machine this is and *what roles* it should have:
```nix
# hosts/nixos-lt/default.nix
{
  roles = ["common" "laptop" "desktop" "nfs-client" "impermanent" "gaming" "docker"];
  hostUsers = ["lucas"];
}
```

**Roles** define *what functionality* a machine should have:
- **common**: Base system configuration shared across all hosts
- **desktop**: Desktop environment (Hyprland, SDDM, theming via Stylix)
- **laptop**: Laptop-specific optimizations and hardware support
- **impermanent**: Impermanence configuration for stateless systems
- **nfs-client**: Network file system client configuration
- **gaming**: Steam, Proton, and gaming-related packages
- **docker**: Docker daemon with auto-prune and journald logging

This separation means you can:
- Add the "desktop" role to any host to get a full desktop environment
- Create new hosts by combining existing roles
- Modify a role once and have it apply to all hosts using it

### Users ↔ Profiles Abstraction

**Users** define system-level user accounts, while **profiles** define user environment configurations:

```nix
# users/lucas/default.nix - User identity and personal settings
{
  profiles = ["common" "desktop-user" "developer" "gamer"];
  # Personal git config, ssh settings, etc.
}
```

**Profiles** define collections of user software and settings:
- **common**: Basic user configuration with essential tools (vim, btop, etc.)
- **developer**: Development environment with programming tools
- **desktop-user**: Desktop user environment for GUI workflows
- **gamer**: MangoHud overlay, Discord

This means multiple users can share profiles, and users can mix different profiles for different purposes.

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
- **Nixievim** - My custom Neovim distribution built with nixvim
- **Alacritty** - Terminal emulator
- **Tmux** - Auto-attaches to a persistent `dev` session on shell start
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
# Edit host-specific secrets
sops secrets/nixos-lt.yaml

# Edit shared system secrets
sops secrets/shared.yaml
```

**Creating User Secrets**:
```bash
# Edit user-specific secrets
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
  github-token = {
    path = "${config.home.homeDirectory}/.config/gh/token";
  };
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

Create `hosts/<hostname>/default.nix` and `hosts/<hostname>/disko-config.nix`. See `hosts/nixos-lt/` for a reference. Register the host in `flake.nix`.

#### 2 — Add a placeholder sops key

Add a placeholder age key under `keys:` in `.sops.yaml` and add the appropriate `creation_rules` entry. The real key is derived from the SSH host key after first boot.

Create the host secrets file (requires YubiKey):
```bash
sops secrets/<hostname>.yaml
```

Commit and push so comin can pull the config on first boot.

#### 3 — Install

Boot from the [livecd](hosts/nixos-livecd/) image, clone the repo, then:

```bash
# Partition and format disks
sudo disko --mode disko hosts/<hostname>/disko-config.nix

# Generate hardware config
sudo nixos-generate-config --no-filesystems --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/<hostname>/hardware-config.nix

# Mount EFI if disko doesn't manage it
mount /dev/<efi-partition> /mnt/boot

# Install
sudo nixos-install --flake .#<hostname>
```

#### 4 — Wire up sops after first boot

The SSH host key is generated on first boot. Get the age public key derived from it:

```bash
# On the new host
ssh-to-age < /persist/etc/ssh/ssh_host_ed25519_key.pub  # impermanent
# or: ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

On your dev machine (YubiKey required):
```bash
# Replace the placeholder in .sops.yaml with the real age key
# Then re-encrypt all files that include this host as a recipient
sops updatekeys secrets/shared.yaml
sops updatekeys secrets/users/lucas.yaml
git add .sops.yaml secrets/
git commit -m "chore(sops): add <hostname> host key"
git push
```

comin will pick up the changes automatically.

### Adding New Roles

Create a new file in `roles/` directory:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "role-name" config.roles) {
  # Role-specific configuration
}
```

### User Configuration

User configurations are located in `users/username/default.nix`. Each user can specify:
- Home Manager profiles
- Personal packages
- Git configuration
- SSH settings
- Persistent files and folders (for impermanence)

## 💡 Inspiration

This configuration architecture is inspired by the **nixos-unified autowire feature**, which provides automatic scanning and wiring of flake configurations. While this repo implements similar concepts manually, it demonstrates:

- Automatic discovery of configuration modules
- Clean separation between system roles and user profiles  
- Composable configuration patterns
- Reduced boilerplate through reusable abstractions

The goal is to eliminate repetitive configuration management while maintaining clear organization as the number of hosts and users scales.

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
2. **Custom lib functions** for configuration generation
3. **Role-based system** for composable configurations
4. **Profile-based user management** for different user types
5. **Host-specific overrides** for hardware and environment differences

The `lib.nix` file provides utility functions for:
- Automatic configuration discovery
- NixOS system generation
- Module composition and organization

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `nixos-rebuild build --flake .#<hostname>`
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [NixOS](https://nixos.org/) for the amazing operating system
- [Home Manager](https://github.com/nix-community/home-manager) for user configuration management
- [Stylix](https://github.com/nix-community/stylix) for system theming
- [Hyprland](https://hyprland.org/) for the beautiful desktop environment
- [Impermanence](https://github.com/nix-community/impermanence) for stateless system support