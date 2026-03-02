{pkgs, ...}: let
  roles = ["common" "desktop" "nfs-client" "impermanent" "gaming" "docker"];
  hostUsers = ["lucas"];
in {
  system.stateVersion = "25.11";

  inherit roles hostUsers;

  imports = [
    ./disko-config.nix
    ./hardware-config.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid" "usb_storage"];
      kernelModules = ["amdgpu"];
    };
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelModules = ["kvm-amd"];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "loglevel=3"
      "quiet"
    ];
  };

  services.xserver.videoDrivers = ["amdgpu"];
}
