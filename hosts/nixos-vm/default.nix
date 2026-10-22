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

  roles = {
    common.enable = true;
    nfsClient.enable = true;
    desktop.enable = true;
  };

  hostUsers = {
    lucas.enable = true;
  };

  services.qemuGuest.enable = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # VM can't decrypt SOPS passwords (no host keys at build time); use empty ones.
  users.users =  lib.genAttrs activeUsers (_: {
    initialPassword = lib.mkForce "";
    hashedPasswordFile = lib.mkForce null;
  });
}
