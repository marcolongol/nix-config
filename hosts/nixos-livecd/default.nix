{
  pkgs,
  users,
  lib,
  modulesPath,
  ...
}: let
  # Collect SSH keys for the live CD's built-in `nixos` user so we can SSH in
  # during installation without a password.
  #
  # We use the `users` specialArg (injected by lib.nix) rather than a relative
  # path like ../../../users/lucas/pubkeys.nix, because relative paths that
  # escape the host directory break under pure evaluation mode (--pure-eval /
  # flake evaluation).  The specialArg is already resolved to an absolute store
  # path before evaluation begins, so it is safe to use here.
  #
  # To add another installer's key, append:
  #   (import (users.<name> + "/pubkeys.nix")).ssh.publicKey
  authorizedKeys = [
    (import (users.lucas + "/pubkeys.nix")).ssh.publicKey
  ];

  repoUrl = "https://github.com/marcolongol/nix-config";

  roles = ["common"];
  # hostUsers is intentionally empty on the live CD.  The normal hostUsers
  # mechanism in modules/nixos/default.nix creates user accounts backed by
  # SOPS-encrypted hashed passwords.  SOPS is disabled on the live CD (no
  # persistent host key to decrypt secrets), so adding a real user via
  # hostUsers would result in an account with no usable password.  Instead,
  # we grant SSH access by injecting public keys into the stock `nixos` user
  # below.
  hostUsers = [];
in {
  system.stateVersion = "25.11";

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  inherit roles hostUsers;

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  services.comin.enable = lib.mkForce false;

  # Clear all SOPS configuration: the live CD has no persistent host key to
  # decrypt secrets, so nothing here can be decrypted.  We also clear
  # defaultSopsFile (which common.nix sets to secrets/<hostName>.yaml) to
  # avoid an activation error from a file that does not exist for this host.
  sops.secrets = lib.mkForce {};
  sops.age.sshKeyPaths = lib.mkForce [];
  sops.defaultSopsFile = lib.mkForce "/dev/null";

  # Stylix is always injected via lib.nix but requires a base16 scheme with
  # no default, which would cause an eval error — disable it for the live CD
  stylix.enable = false;

  # Grant SSH access to the live CD's built-in `nixos` user using the
  # installer's public key.  This is the only way to get key-based SSH access
  # without SOPS (which is disabled above): we bypass the normal user module
  # entirely and write the key directly into the stock account.
  users.users.nixos.openssh.authorizedKeys.keys = authorizedKeys;

  environment.systemPackages = with pkgs; [
    disko
    # Helper script summarising the install workflow
    (writeShellScriptBin "install-help" ''
      echo ""
      echo "NixOS Installation Steps"
      echo "========================"
      echo ""
      echo "0. Connect to the network (if not already):"
      echo "   nmtui"
      echo "   # The repo is cloned automatically to /root/nix-config once online."
      echo "   # Note: /root/nix-config is in RAM — it will be lost on reboot."
      echo ""
      echo "1. Configure git identity (required for committing):"
      echo "   git config --global user.name  'Your Name'"
      echo "   git config --global user.email 'you@example.com'"
      echo ""
      echo "2. Generate and commit hardware config:"
      echo "   sudo nixos-generate-config --no-filesystems --root /mnt"
      echo "   cp /mnt/etc/nixos/hardware-configuration.nix /root/nix-config/hosts/<hostname>/hardware-config.nix"
      echo "   cd /root/nix-config"
      echo "   git add hosts/<hostname>/hardware-config.nix"
      echo "   git commit -m 'feat(<hostname>): add hardware config'"
      echo "   # Push before rebooting so the config is not lost:"
      echo "   git push"
      echo ""
      echo "3. Partition & format disks (disko):"
      echo "   sudo disko --mode disko /root/nix-config/hosts/<hostname>/disko-config.nix"
      echo ""
      echo "4. Install:"
      echo "   sudo nixos-install --flake /root/nix-config#<hostname>"
      echo ""
      echo "Tip: run 'ip addr' to find your IP, then SSH in as 'nixos' (key-based, no password)."
      echo ""
    '')
  ];

  # Clone the nix-config repo once the network is up so it's ready to use.
  systemd.services.clone-nix-config = {
    description = "Clone nix-config repository";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    requires = ["network-online.target"];
    unitConfig.ConditionPathExists = "!/root/nix-config";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git clone ${repoUrl} /root/nix-config";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
      TimeoutStartSec = "60s";
    };
  };

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [pkgs.nixos-bgrt-plymouth];
  };
}
