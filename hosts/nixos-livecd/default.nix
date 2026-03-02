{
  pkgs,
  users,
  lib,
  modulesPath,
  ...
}: let
  # Collect SSH keys from all installer users. We use the `users` specialArg
  # (already passed by lib.nix) rather than a relative path, because relative
  # paths outside the host directory break in pure eval mode.
  # Add more users here as needed: (import (users.<name> + "/pubkeys.nix")).ssh
  authorizedKeys = [
    (import (users.lucas + "/pubkeys.nix")).ssh
  ];

  repoUrl = "https://github.com/marcolongol/nix-config";

  roles = ["common"];
  hostUsers = [];
in {
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  inherit roles hostUsers;

  isoImage.squashfsCompression = "gzip -Xcompression-level 1";

  services.comin.enable = lib.mkForce false;
  system.autoUpgrade.enable = lib.mkForce false;
  sops.secrets = lib.mkForce {};
  sops.age.sshKeyPaths = lib.mkForce [];

  # Stylix is always injected via lib.nix but requires a base16 scheme with
  # no default, which would cause an eval error — disable it for the live CD
  stylix.enable = false;

  users.users = {
    nixos.openssh.authorizedKeys.keys = authorizedKeys;
  };

  environment.systemPackages = with pkgs; [
    disko
    age
    nixos-anywhere
    # Helper script summarising the install workflow
    (writeShellScriptBin "install-help" ''
      echo ""
      echo "NixOS Installation Steps"
      echo "========================"
      echo ""
      echo "1. Partition & format disks (disko):"
      echo "   sudo disko --mode disko /root/nix-config/hosts/<hostname>/disko-config.nix"
      echo ""
      echo "2. Generate hardware config:"
      echo "   sudo nixos-generate-config --no-filesystems --root /mnt"
      echo "   cp /mnt/etc/nixos/hardware-configuration.nix /root/nix-config/hosts/<hostname>/hardware-config.nix"
      echo ""
      echo "3. Commit the hardware config, then install:"
      echo "   sudo nixos-install --flake /root/nix-config#<hostname>"
      echo ""
      echo "Tip: run 'ip addr' to find your IP, then SSH in as lucas or nixos."
      echo ""
    '')
  ];

  # Clone the nix-config repo once the network is up so it's ready to use
  systemd.services.clone-nix-config = {
    description = "Clone nix-config repository";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    unitConfig.ConditionPathExists = "!/root/nix-config";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.git}/bin/git clone ${repoUrl} /root/nix-config";
      RemainAfterExit = true;
    };
  };

  boot.plymouth = {
    enable = true;
    theme = "nixos-bgrt";
    themePackages = [pkgs.nixos-bgrt-plymouth];
  };

  system.stateVersion = "25.11";
}
