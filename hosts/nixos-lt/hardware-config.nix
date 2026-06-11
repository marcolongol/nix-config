{
  modulesPath,
  inputs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    # Generic hardware profiles from nixos-hardware. No HP Victus 16-r0xxx
    # profile exists upstream; common-cpu-intel transitively imports
    # common-gpu-intel (VA-API stack for UHD 770). TLP itself is owned by
    # roles/laptop.nix, not common-pc-laptop, so the role stays scoped.
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid"];
    kernelModules = ["kvm-intel"];
  };

  # NVIDIA Graphics Configuration
  # GeForce RTX 4060 Max-Q with Intel UHD Graphics 770 hybrid setup
  hardware.nvidia-custom = {
    enable = true;

    # Hybrid graphics configuration (Intel + NVIDIA)
    hybrid = {
      enable = true;
      mode = "offload"; # Use Intel by default, NVIDIA on demand for better battery life
      busId = {
        intel = "PCI:0:2:0"; # Intel Alder Lake-HX GT1 [UHD Graphics 770]
        nvidia = "PCI:1:0:0"; # NVIDIA GeForce RTX 4060 Max-Q / Mobile
      };
    };

    # Power management for laptop (RTX 40 series supports fine-grained)
    powerManagement = {
      enable = true;
      finegrained = true; # RTX 4060 supports fine-grained power management
    };

    # Additional features
    enableCUDA = false; # Set to true if you need CUDA for ML/compute workloads
    enableVulkan = true; # Enable for gaming and modern graphics applications

    # Settings
    settings = {
      modesetting = true;
      useGBM = true; # Better Wayland support
      forceCompositionPipeline =
        false; # Enable if you experience screen tearing
    };
  };

  hardware.enableAllFirmware = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}
