{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
