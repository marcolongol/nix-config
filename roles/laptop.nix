{
  config,
  lib,
  pkgs,
  ...
}: let
  activeUsers = lib.attrNames (lib.filterAttrs (_: u: u.enable) config.hostUsers);
in {
  options.roles.laptop.enable = lib.mkEnableOption "laptop power management";

  config = lib.mkIf config.roles.laptop.enable {
    # TLP replaces auto-cpufreq (which only touched the CPU). Inlined from nixos-hardware's
    # common-pc-laptop so desktop builds are unaffected.
    services.tlp = {
      enable = lib.mkDefault (!config.services.power-profiles-daemon.enable);
      settings = {
        # intel_pstate "powersave" still turbos on demand; "performance" pinned ~3.5 GHz with k3s idle.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # EPP hint for intel_pstate.
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # Turbo on AC only.
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Stops TLP re-enabling btusb runtime PM (see modprobe option below).
        USB_EXCLUDE_BTUSB = 1;
      };
    };

    # Shut down cleanly at critical battery; PowerOff over Hibernate (no resumeDevice set).
    services.upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };

    # upower only acts at percentageAction; poweralertd turns warning levels into notifications.
    home-manager.users = lib.genAttrs activeUsers (_: {
      services.poweralertd = {
        enable = true;
        # -i line-power: ACAD alerts duplicate battery ones. -s: no state replay at login.
        extraArgs = ["-s" "-i" "line-power"];
      };
    });

    # btusb enables runtime PM at probe; TLP's exclusion doesn't revert it.
    boot.extraModprobeConfig = "options btusb enable_autosuspend=0";

    # CNVi shares one antenna between WiFi and BT; drop WiFi when docked on ethernet.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "wifi-off-on-ethernet" ''
          [ "$(${pkgs.networkmanager}/bin/nmcli -g GENERAL.TYPE device show "$1")" = ethernet ] || exit 0
          case "$2" in
            up) ${pkgs.networkmanager}/bin/nmcli radio wifi off ;;
            down) ${pkgs.networkmanager}/bin/nmcli radio wifi on ;;
          esac
        '';
      }
    ];
  };
}
