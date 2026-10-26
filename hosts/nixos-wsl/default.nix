{
  inputs,
  lib,
  ...
}: {
  system.stateVersion = "25.11";

  imports = [inputs.nixos-wsl.nixosModules.default];

  # Standalone: stock `nixos` user from NixOS-WSL, no repo users or home-manager.
  wsl = {
    enable = true;
    defaultUser = "nixos";
  };

  roles.common.enable = true;

  # WSL owns networking and resolv.conf; disk/firmware daemons have nothing to manage.
  networking.networkmanager.enable = lib.mkForce false;
  services = {
    resolved.enable = lib.mkForce false;
    avahi.enable = lib.mkForce false;
    fwupd.enable = lib.mkForce false;
    smartd.enable = lib.mkForce false;
  };

  # No host age key until first boot; re-enable once added to .sops.yaml.
  sops.secrets = lib.mkForce {};
  sops.defaultSopsFile = lib.mkForce "/dev/null";

  # Stylix has no default base16 scheme; eval fails without disabling it.
  stylix.enable = false;
}
