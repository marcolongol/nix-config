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
      description = "Enable CoreCtrl for GPU fan/clock control. Grants wheel users polkit access.";
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
      ++ optionals cfg.enableOpenCL [clinfo]
      ++ optionals cfg.enableCorectrl [corectrl];

    # Grant render/video group access for OpenCL/ROCm
    users.users = mkIf cfg.enableOpenCL (
      genAttrs
      (lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers))
      (_: {extraGroups = ["render" "video"];})
    );

    # Allow wheel users to run CoreCtrl without password prompt
    security.polkit.extraConfig = mkIf cfg.enableCorectrl ''
      polkit.addRule(function(action, subject) {
        if ((action.id == "org.corectrl.helper.init" ||
             action.id == "org.corectrl.helperkiller.init") &&
            subject.local == true &&
            subject.active == true &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
