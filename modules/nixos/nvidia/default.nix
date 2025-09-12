# NVIDIA Graphics Module
# Provides NVIDIA driver configuration with optional hybrid graphics support
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.hardware.nvidia-custom;
in {
  options.hardware.nvidia-custom = {
    enable = mkEnableOption "Enable NVIDIA graphics drivers";

    package = mkOption {
      type = types.package;
      default = config.boot.kernelPackages.nvidiaPackages.stable;
      description = "NVIDIA driver package to use";
    };

    powerManagement = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable NVIDIA power management (experimental)";
      };

      finegrained = mkOption {
        type = types.bool;
        default = false;
        description = "Enable fine-grained power management (RTX 30 series and newer)";
      };
    };

    hybrid = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable hybrid graphics (NVIDIA Optimus/Prime)";
      };

      mode = mkOption {
        type = types.enum ["sync" "offload" "reverse-sync"];
        default = "offload";
        description = ''
          Prime mode:
          - sync: Always use NVIDIA GPU
          - offload: Use integrated GPU by default, NVIDIA on demand
          - reverse-sync: Use NVIDIA as primary, integrated as secondary
        '';
      };

      busId = {
        nvidia = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "PCI:1:0:0";
          description = "Bus ID for NVIDIA GPU (e.g., PCI:1:0:0)";
        };

        intel = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "PCI:0:2:0";
          description = "Bus ID for Intel GPU (e.g., PCI:0:2:0)";
        };

        amd = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "PCI:4:0:0";
          description = "Bus ID for AMD GPU (e.g., PCI:4:0:0)";
        };
      };

      intelBusId = mkOption {
        type = types.nullOr types.str;
        default = cfg.hybrid.busId.intel;
        description = "Deprecated: Use hybrid.busId.intel instead";
      };

      nvidiaBusId = mkOption {
        type = types.nullOr types.str;
        default = cfg.hybrid.busId.nvidia;
        description = "Deprecated: Use hybrid.busId.nvidia instead";
      };
    };

    settings = {
      modesetting = mkOption {
        type = types.bool;
        default = true;
        description = "Enable kernel modesetting";
      };

      forceCompositionPipeline = mkOption {
        type = types.bool;
        default = false;
        description = "Force composition pipeline (can help with screen tearing)";
      };

      useGBM = mkOption {
        type = types.bool;
        default = true;
        description = "Use GBM as the Wayland backend";
      };

      hardware = {
        enableRedistributableFirmware = mkOption {
          type = types.bool;
          default = true;
          description = "Enable redistributable firmware";
        };
      };
    };

    blacklistNouveau = mkOption {
      type = types.bool;
      default = true;
      description = "Blacklist nouveau driver";
    };

    enableCUDA = mkOption {
      type = types.bool;
      default = false;
      description = "Enable CUDA support";
    };

    enableOpenCL = mkOption {
      type = types.bool;
      default = false;
      description = "Enable OpenCL support";
    };

    enableVulkan = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Vulkan support";
    };
  };

  config = mkIf cfg.enable {
    # Basic NVIDIA configuration
    services.xserver.videoDrivers = ["nvidia"];

    # Hardware configuration
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs;
          mkMerge [
            (mkIf cfg.enableVulkan [
              nvidia-vaapi-driver
              vaapiVdpau
              libvdpau-va-gl
            ])
            (mkIf cfg.enableOpenCL [ocl-icd opencl-headers])
          ];
      };

      nvidia = {
        modesetting.enable = cfg.settings.modesetting;
        powerManagement.enable = cfg.powerManagement.enable;
        powerManagement.finegrained = cfg.powerManagement.finegrained;
        open = false; # Use proprietary driver
        nvidiaSettings = true; # Enable nvidia-settings
        package = cfg.package;

        # Force composition pipeline if enabled
        forceFullCompositionPipeline = cfg.settings.forceCompositionPipeline;

        # Prime configuration for hybrid graphics
        prime =
          mkIf cfg.hybrid.enable {
            sync.enable = cfg.hybrid.mode == "sync";
            offload = {
              enable = cfg.hybrid.mode == "offload";
              enableOffloadCmd = cfg.hybrid.mode == "offload";
            };
            reverseSync.enable = cfg.hybrid.mode == "reverse-sync";

            # Use new busId options if available, fall back to deprecated ones
            nvidiaBusId =
              if cfg.hybrid.busId.nvidia != null
              then cfg.hybrid.busId.nvidia
              else cfg.hybrid.nvidiaBusId;

            intelBusId =
              if cfg.hybrid.busId.intel != null
              then cfg.hybrid.busId.intel
              else cfg.hybrid.intelBusId;
          }
          # Only set amdgpuBusId if it's actually configured
          // (lib.optionalAttrs (cfg.hybrid.busId.amd != null) {
            amdgpuBusId = cfg.hybrid.busId.amd;
          });
      };

      enableRedistributableFirmware =
        cfg.settings.hardware.enableRedistributableFirmware;
    };

    # Environment variables
    environment = {
      variables = mkMerge [
        # Only set NVIDIA-specific variables when NOT in offload mode
        (mkIf (!cfg.hybrid.enable || cfg.hybrid.mode != "offload") {
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        })
        (mkIf cfg.settings.useGBM {GBM_BACKEND = "nvidia-drm";})
        (mkIf cfg.enableCUDA {
          CUDA_PATH = "${pkgs.cudatoolkit}";
          LD_LIBRARY_PATH = lib.mkForce "${pkgs.cudatoolkit}/lib:${pkgs.cudatoolkit.lib}/lib";
        })
      ];

      systemPackages = with pkgs;
        mkMerge [
          # Always include basic NVIDIA tools and Mesa for hybrid graphics
          [
            nvidia-vaapi-driver
            egl-wayland
            mesa
            glxinfo # For debugging OpenGL issues
          ]
          # CUDA packages
          (mkIf cfg.enableCUDA [cudatoolkit cudaPackages.cudnn])
          # OpenCL packages
          (mkIf cfg.enableOpenCL [clinfo opencl-info])
          # Vulkan packages
          (mkIf cfg.enableVulkan [
            vulkan-tools
            vulkan-loader
            vulkan-validation-layers
          ])
        ];
    };

    # Blacklist nouveau if enabled
    boot.blacklistedKernelModules = mkIf cfg.blacklistNouveau ["nouveau"];

    # Kernel parameters for better stability
    boot.kernelParams =
      ["nvidia-drm.modeset=1"]
      ++ optionals cfg.settings.useGBM
      ["nvidia.NVreg_PreserveVideoMemoryAllocations=1"];

    # Load NVIDIA modules early
    boot.initrd.kernelModules = ["nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];

    # Warnings for missing bus IDs in hybrid mode
    warnings =
      optionals (cfg.hybrid.enable
        && cfg.hybrid.busId.nvidia == null
        && cfg.hybrid.nvidiaBusId == null) [
        ''
          NVIDIA hybrid graphics enabled but no NVIDIA bus ID specified. Use 'lspci | grep -E "(VGA|3D)"' to find the correct bus ID.''
      ]
      ++ optionals (cfg.hybrid.enable
        && cfg.hybrid.busId.intel == null
        && cfg.hybrid.intelBusId == null
        && cfg.hybrid.busId.amd == null) [
        ''
          NVIDIA hybrid graphics enabled but no integrated GPU bus ID specified. Use 'lspci | grep -E "(VGA|3D)"' to find the correct bus ID.''
      ];
  };
}
