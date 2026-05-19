{
  config,
  inputs,
  lib,
  users,
  profiles,
  homeManagerModules,
  secretsPath,
  ...
}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  options = {
    hostUsers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options.enable = lib.mkEnableOption "this user on this host";
      });
      default = {};
      description = "Users to enable on this host";
    };

    persistentFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of system folders to persist under /persist";
    };

    persistentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of system files to persist under /persist";
    };
  };

  config = lib.mkIf (activeUsers != []) {
    users.mutableUsers = false;

    sops.secrets = lib.mkMerge (map (userName: {
        "user-password-${userName}" = {
          sopsFile = secretsPath + "/users/${userName}.yaml";
          key = "hashed-password";
          neededForUsers = true;
        };
      })
      activeUsers);

    users.users = lib.genAttrs activeUsers (userName: {
      isNormalUser = true;
      home = "/home/${userName}";
      extraGroups =
        ["wheel" "networkmanager" "plugdev"]
        ++ lib.optionals config.roles.docker.enable ["docker"];
      hashedPasswordFile = config.sops.secrets."user-password-${userName}".path;
      openssh.authorizedKeys.keys = let
        pubkeysPath = "${users.${userName}}/pubkeys.nix";
      in
        lib.optionals (users ? ${userName} && builtins.pathExists pubkeysPath)
        [(import pubkeysPath).ssh.publicKey];
    });

    # GPG auth subkey (stored on YubiKey) via pam_ssh_agent_auth.
    # gpg-agent exposes the [A] subkey as an SSH key; pam_ssh_agent_auth
    # checks it against /etc/ssh/authorized_keys.d/%u (populated from
    # openssh.authorizedKeys.keys). UIF touch on the auth slot ensures
    # physical presence on every auth. Password remains as fallback.
    security.pam.sshAgentAuth.enable = true;

    security.pam.services = {
      login.sshAgentAuth = true;
      sudo.sshAgentAuth = true;
      hyprlock.sshAgentAuth = true;
      sddm.sshAgentAuth = true;
    };

    # sudo must run PAM so the touch-to-auth path triggers.
    security.sudo.wheelNeedsPassword = true;

    home-manager = {
      extraSpecialArgs = {
        inherit inputs secretsPath;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      users = lib.genAttrs activeUsers (
        userName:
          if users ? ${userName}
          then {
            imports =
              [
                (import users.${userName})
                inputs.zen-browser.homeModules.beta
                inputs.sops-nix.homeManagerModules.sops
              ]
              ++ (lib.attrValues profiles) ++ (lib.attrValues homeManagerModules);
          }
          else {
            home.stateVersion = "24.05";
            imports = (lib.attrValues profiles) ++ (lib.attrValues homeManagerModules);
          }
      );
    };
  };
}
