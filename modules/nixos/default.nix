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
  # Derive the list of active users from the attrset option
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);

  # Collect YubiKey serials declared in each active user's pubkeys.nix.
  # Users without a pubkeys.nix or without a `yubikeys` field contribute nothing.
  userYubikeySerials = lib.concatMap (
    userName: let
      pubkeysPath = "${users.${userName}}/pubkeys.nix";
    in
      if users ? ${userName} && builtins.pathExists pubkeysPath
      then map (k: k.serial) ((import pubkeysPath).yubikeys or [])
      else []
  ) activeUsers;

  yubikeyAuthEnabled = userYubikeySerials != [];
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

    # YubiKey HMAC challenge-response auth. Enabled only when at least one
    # active user declares a YubiKey serial in their pubkeys.nix. Per-user
    # challenge files live at ~/.yubico/challenge-<serial> (impermanence
    # persists them via the user's persistentFolders).
    security.pam.yubico = lib.mkIf yubikeyAuthEnabled {
      enable = true;
      mode = "challenge-response";
      control = "sufficient";
      id = userYubikeySerials;
    };

    # YubiKey-only auth: enable yubico and explicitly disable the unix
    # password fallback on each affected service. With pam_unix removed
    # from the auth stack, pam_yubico is the only module that can satisfy
    # the auth check before pam_deny.
    security.pam.services = lib.mkIf yubikeyAuthEnabled {
      login = { yubicoAuth = true; unixAuth = true; };
      sudo = { yubicoAuth = true; unixAuth = true; };
      hyprlock = { yubicoAuth = true; unixAuth = true; };
      sddm = { yubicoAuth = true; unixAuth = true; };
    };

    # When YubiKey auth is on, sudo must run PAM (not NOPASSWD) so the
    # touch-to-auth path actually triggers. Password remains as fallback.
    security.sudo.wheelNeedsPassword = lib.mkIf yubikeyAuthEnabled true;

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
