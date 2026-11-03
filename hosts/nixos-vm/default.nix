{
  config,
  lib,
  ...
}: {
  system.stateVersion = "26.05";

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

  # VM can't decrypt SOPS passwords (no host keys at build time); use a
  # throwaway password instead. Local test VM only.
  users.users = lib.genAttrs config.omninix.activeUsers (_: {
    initialPassword = lib.mkForce "vm";
    hashedPasswordFile = lib.mkForce null;
  });
}
