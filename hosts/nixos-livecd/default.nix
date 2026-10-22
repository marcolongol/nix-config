{
  pkgs,
  users,
  lib,
  modulesPath,
  ...
}: let
  # SSH keys for the live CD's `nixos` user. Use the `users` specialArg, not a relative
  # path: paths escaping the host dir break under pure eval.
  # To add another key: (import (users.<name> + "/pubkeys.nix")).ssh.publicKey
  authorizedKeys = [
    (import (users.lucas + "/pubkeys.nix")).ssh.publicKey
  ];

  repoUrl = "https://github.com/marcolongol/nix-config";
in {
  system.stateVersion = "25.11";

  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # hostUsers stays empty: user accounts need SOPS passwords, which the live CD can't decrypt.
  roles.common.enable = true;

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  services.comin.enable = lib.mkForce false;

  # No persistent host key, so clear SOPS config. defaultSopsFile is set by common.nix to a
  # per-host file that doesn't exist here.
  sops.secrets = lib.mkForce {};
  sops.age.sshKeyPaths = lib.mkForce [];
  sops.defaultSopsFile = lib.mkForce "/dev/null";

  # Stylix has no default base16 scheme; eval fails without disabling it.
  stylix.enable = false;

  # Bypass the user module (needs SOPS) and inject the key into the stock `nixos` user.
  users.users.nixos.openssh.authorizedKeys.keys = authorizedKeys;

  environment.systemPackages = with pkgs; [
    disko
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