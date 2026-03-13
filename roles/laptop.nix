{
  config,
  lib,
  ...
}: {
  options.roles.laptop.enable = lib.mkEnableOption "laptop power management";

  config = lib.mkIf config.roles.laptop.enable {
    powerManagement = {
      enable = true;
      powertop.enable = true;
    };

    services = {
      thermald.enable = true;
      auto-cpufreq = {
        enable = true;
        settings = {
          battery = {
            governor = "powersave";
            turbo = "never";
          };
          charger = {
            governor = "performance";
            turbo = "always";
          };
        };
      };
    };
  };
}