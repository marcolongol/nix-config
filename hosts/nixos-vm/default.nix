{
  config,
  lib,
  ...
}:
let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in
{
  system.stateVersion = "25.11";

  # Example host configuration
  roles = {
    common.enable = true;
    nfsClient.enable = true;
    desktop.enable = true;
  };

  hostUsers = {
    lucas.enable = true;
  };

  services.qemuGuest.enable = true;

  # Basic filesystem configuration for VM
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Boot loader configuration for VM
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set empty passwords for all normal users in the VM for easy initial access.
  # Needed because the VM cannot decrypt SOPS user passwords (no host SSH keys at build time).
  users.users =  lib.genAttrs activeUsers (_: {
    initialPassword = lib.mkForce "";
    hashedPasswordFile = lib.mkForce null;
  });
}
