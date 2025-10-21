{
  config,
  inputs,
  lib,
  users,
  profiles,
  homeManagerModules,
  secretsPath,
  ...
}: {
  options = {
    roles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of roles this host should assume";
    };

    hostUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of users this host should have";
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

  config = lib.mkIf (config.hostUsers != []) {
    users.mutableUsers = false;

    sops.secrets = lib.mkMerge (map (userName: {
        "user-password-${userName}" = {
          sopsFile = secretsPath + "/users/${userName}.yaml";
          key = "hashed-password";
          neededForUsers = true;
        };
      })
      config.hostUsers);

    users.users = lib.genAttrs config.hostUsers (userName: {
      isNormalUser = true;
      home = "/home/${userName}";
      extraGroups = ["wheel" "networkmanager" "docker"];
      hashedPasswordFile = config.sops.secrets."user-password-${userName}".path;
    });

    home-manager = {
      extraSpecialArgs = {
        inherit inputs secretsPath;
      };
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bak";
      users = lib.genAttrs config.hostUsers (
        userName:
          if users ? ${userName}
          then {
            imports =
              [
                (import users.${userName})
                inputs.impermanence.homeManagerModules.impermanence
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
