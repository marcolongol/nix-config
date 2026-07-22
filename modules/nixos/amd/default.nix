# AMD Graphics Module
# Provides AMD GPU driver configuration with optional ROCm/OpenCL and CoreCtrl support
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.amd-custom;
in {
  options.hardware.amd-custom = {
    enable = mkEnableOption "AMD graphics drivers";

    enable32Bit = mkOption {
      type = types.bool;
      default = true;
      description = "Enable 32-bit graphics support (needed for Steam/Wine)";
    };

    enableOpenCL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable OpenCL support via ROCm. Adds users to the render and video groups.";
    };

    enableCorectrl = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CoreCtrl for GPU fan/clock control. Adds users to the corectrl group.";
    };

    enableRedistributableFirmware = mkOption {
      type = types.bool;
      default = true;
      description = "Enable redistributable firmware (includes amdgpu firmware blobs)";
    };
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["amdgpu"];

    boot.kernelPackages = mkDefault pkgs.linuxPackages_latest;
    boot.initrd.kernelModules = ["amdgpu"];

    hardware = {
      enableRedistributableFirmware = cfg.enableRedistributableFirmware;
      graphics = {
        enable = true;
        enable32Bit = cfg.enable32Bit;
        extraPackages = with pkgs;
          optionals cfg.enableOpenCL [rocmPackages.clr];
      };
    };

    environment.variables = {
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";
    };

    environment.systemPackages = with pkgs;
      [rocmPackages.rocm-smi]
      ++ optionals cfg.enableOpenCL [clinfo];

    # NixOS ships CoreCtrl: package + polkit rule (authorizes the corectrl group)
    programs.corectrl.enable = cfg.enableCorectrl;

    # Grant group access: render/video for OpenCL/ROCm, corectrl for CoreCtrl
    users.users =
      genAttrs
      (attrNames (filterAttrs (_: u: u.enable) config.hostUsers))
      (_: {
        extraGroups =
          optionals cfg.enableOpenCL ["render" "video"]
          ++ optionals cfg.enableCorectrl ["corectrl"];
      });
  };
}
