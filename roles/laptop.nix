{
  config,
  lib,
  ...
}:
lib.mkIf (lib.elem "laptop" config.roles) {
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
}
