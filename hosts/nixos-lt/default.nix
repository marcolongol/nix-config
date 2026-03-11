{pkgs, lib, ...}: let
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

  # Monitor layout and workspace bindings
  # eDP-1: Chimei Innolux 1920x1080, built-in display, max refresh 144Hz
  home-manager.users = lib.genAttrs hostUsers (_: {
    wayland.windowManager.hyprland.settings = {
      monitor = [
        "eDP-1,1920x1080@144,0x0,1"
      ];
    };
  });

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
