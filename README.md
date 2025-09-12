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
  roles = ["common" "laptop" "desktop" "nfs-client" "impermanent"];
  hostUsers = ["lucas"];
}
```

**Roles** define *what functionality* a machine should have:
- **common**: Base system configuration shared across all hosts
- **desktop**: Desktop environment (Hyprland, SDDM, theming via Stylix)
- **laptop**: Laptop-specific optimizations and hardware support
- **impermanent**: Impermanence configuration for stateless systems
- **nfs-client**: Network file system client configuration

This separation means you can:
- Add the "desktop" role to any host to get a full desktop environment
- Create new hosts by combining existing roles
- Modify a role once and have it apply to all hosts using it

### Users ↔ Profiles Abstraction

**Users** define system-level user accounts, while **profiles** define user environment configurations:

```nix
# users/lucas/default.nix - User identity and personal settings
{
  profiles = ["common" "desktop-user" "developer"];
  # Personal git config, ssh settings, etc.
}
```

**Profiles** define collections of user software and settings:
- **common**: Basic user configuration with essential tools (vim, btop, etc.)
- **developer**: Development environment with programming tools
- **desktop-user**: Desktop user environment for GUI workflows

This means multiple users can share profiles, and users can mix different profiles for different purposes.

### Key Components

#### Desktop Environment (Desktop Role)
- **Hyprland** - Modern Wayland compositor with UWSM support
- **SDDM** - Display manager with astronaut theme
- **Stylix** - System-wide theming with wallpaper-based color schemes
- **Pipewire** - Modern audio system with ALSA, PulseAudio, and JACK support

#### Development Environment (Developer Profile)  
- **Nixievim** - My custom Neovim distribution built with nixvim for declarative configuration
- **Git** with 1Password SSH signing integration
- **Tmux** with session persistence
- **Python** development environment
- **Starship** prompt and **Zsh** shell

#### Core Tools (Common Profile)
- **Alacritty** - Terminal emulator
- **Home Manager** - Declarative user configuration management
- **Btop** - System monitor
- **sops-nix** - Encrypted secrets management for user-level secrets

## 🔐 Secrets Management

This configuration includes a comprehensive secrets management system using **sops-nix** with age encryption, supporting both system-level and user-level secrets.

### Architecture

**System Secrets**: Managed in the `common` role, accessible system-wide:
- `secrets/shared.yaml` - Shared across all hosts
- `secrets/${hostname}.yaml` - Host-specific secrets (e.g., `nixos-lt.yaml`)

**User Secrets**: Managed in user profiles, accessible per-user:
- `secrets/users/${username}.yaml` - User-specific secrets
- `secrets/users/shared.yaml` - Shared across all users

### Configuration Files

**`.sops.yaml`** - Defines encryption keys and access rules:
```yaml
keys:
  - &admin age19r6wen3fypsw5ykk0dj2e2hc0tyw2zlux6mw33c57pfg5jd9mg9sgjp3za
  - &nixos-lt age1k2m2hjlr26pgxvtuesw6wpgxv5kx5je5egck9r3x7rujteh0a3hqypwxry
  - &lucas-user age19r6wen3fypsw5ykk0dj2e2hc0tyw2zlux6mw33c57pfg5jd9mg9sgjp3za

creation_rules:
  # System secrets
  - path_regex: secrets/nixos-lt\.yaml$
    key_groups: [age: [*admin, *nixos-lt]]
  - path_regex: secrets/shared\.yaml$
    key_groups: [age: [*admin, *nixos-lt]]

  # User secrets
  - path_regex: secrets/users/lucas\.yaml$
    key_groups: [age: [*admin, *lucas-user]]
```

### Key Management

**System Keys**: Generated from SSH host keys
```bash
# Host keys are automatically imported during nixos-rebuild
# Located at: /etc/ssh/ssh_host_ed25519_key
```

**User Keys**: Stored in user home directory
```bash
# User age key stored at: ~/.config/sops-nix/key.txt
# Must be manually created with your age secret key
```

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

# Edit shared user secrets
sops secrets/users/shared.yaml
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

### Security Features

- **Age encryption** with multiple recipients for redundancy
- **Automatic key generation** for system hosts
- **Proper file permissions** (0400) for all secret files
- **Impermanence support** - Keys are persisted across reboots
- **Separation of concerns** - System vs user secret isolation

## 🔧 Customization

### Adding a New Host

1. Create a new directory in `hosts/`:
   ```bash
   mkdir hosts/new-host
   ```

2. Create `hosts/new-host/default.nix`:
   ```nix
   {
     system.stateVersion = "25.11";
     
     imports = [
       ./hardware-config.nix
     ];
     
     roles = ["common" "desktop"];
     hostUsers = ["username"];
   }
   ```

3. Generate hardware configuration:
   ```bash
   nixos-generate-config --dir hosts/new-host
   ```

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