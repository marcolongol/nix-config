{...}: let
  roles = ["common" "laptop" "desktop" "nfs-client" "impermanent" "gaming" "docker"];
  hostUsers = ["lucas"];
in {
  system.stateVersion = "25.11";

  inherit roles hostUsers;

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  # Boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid"];
    kernelModules = ["kvm-intel"];
    kernelParams = ["loglevel=3" "quiet"];
  };

  # secrets
  sops = {
    secrets = {
      host-secret = {
        owner = "lucas";
        mode = "0400";
      };
    };
  };
}
