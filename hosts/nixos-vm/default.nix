{
  config,
  lib,
  ...
}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.omninix.hostUsers);
in {
  system.stateVersion = "25.11";

  roles = {
    common.enable = true;
    nfsClient.enable = true;
    desktop.enable = true;
  };

  omninix.hostUsers = {
    lucas = {
      enable = true;
      extraGroups = ["wheel" "networkmanager" "plugdev"];
    };
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

  # Passwordless on purpose (below); omninix fails closed without this.
  omninix.allowInsecureBootstrap = true;

  # VM can't decrypt SOPS passwords (no host keys at build time); use empty ones.
  users.users = lib.genAttrs activeUsers (_: {
    initialPassword = lib.mkForce "";
    hashedPasswordFile = lib.mkForce null;
  });
}
