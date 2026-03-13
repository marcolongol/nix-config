{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = ["xhci_pci" "ahci" "nvme" "usbhid"];
    kernelModules = ["kvm-intel"];
    kernelParams = ["loglevel=3" "quiet"];
  };

  # Thermald custom config: override adaptive DPTF (too aggressive on i7-13700HX)
  # and only intervene at real danger temps, leaving turbo unrestricted below 90°C
  services.thermald.configFile = pkgs.writeText "thermal-conf.xml" ''
    <?xml version="1.0"?>
    <ThermalConfiguration>
    <Platform>
      <Name>nixos-lt i7-13700HX</Name>
      <ProductName>*</ProductName>
      <Preference>PERFORMANCE</Preference>
      <ThermalSensors>
        <ThermalSensor>
          <Type>x86_pkg_temp</Type>
          <AsyncCapable>1</AsyncCapable>
        </ThermalSensor>
      </ThermalSensors>
      <ThermalZones>
        <ThermalZone>
          <Type>x86_pkg_temp</Type>
          <TripPoints>
            <TripPoint>
              <SensorType>x86_pkg_temp</SensorType>
              <Temperature>90000</Temperature>
              <type>passive</type>
              <ControlType>SEQUENTIAL</ControlType>
              <CoolingDevice>
                <index>1</index>
                <type>rapl_controller</type>
                <influence>100</influence>
                <SamplingPeriod>16</SamplingPeriod>
              </CoolingDevice>
            </TripPoint>
            <TripPoint>
              <SensorType>x86_pkg_temp</SensorType>
              <Temperature>100000</Temperature>
              <type>max</type>
              <ControlType>SEQUENTIAL</ControlType>
              <CoolingDevice>
                <index>1</index>
                <type>rapl_controller</type>
                <influence>100</influence>
                <SamplingPeriod>8</SamplingPeriod>
              </CoolingDevice>
            </TripPoint>
          </TripPoints>
        </ThermalZone>
      </ThermalZones>
    </Platform>
    </ThermalConfiguration>
  '';

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
