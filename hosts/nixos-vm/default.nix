{
  config,
  lib,
  ...
}: let
  roles = ["common" "nfs-client" "desktop"];
  hostUsers = ["lucas"];
in {
  system.stateVersion = "25.11";

  # Example host configuration
  inherit roles hostUsers;

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

  # Set empty passwords for all normal users in the VM for easy initial access
  # INFO: This is needed because the VM does not have a way to decrypt the user passwords from
  # SOPS due to lack of SSH keys during vm build time.
  users.users = lib.genAttrs hostUsers (userName: {
    initialPassword = lib.mkForce "";
    hashedPasswordFile = lib.mkForce null;
  });
}
