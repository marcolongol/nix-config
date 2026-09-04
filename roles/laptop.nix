{
  config,
  lib,
  pkgs,
  ...
}: {
  options.roles.laptop.enable = lib.mkEnableOption "laptop power management";

  config = lib.mkIf config.roles.laptop.enable {
    # TLP is the canonical laptop power-management daemon. Tunes CPU, disk
    # APM, USB autosuspend, PCIe ASPM, WiFi power save — auto-cpufreq only
    # touched the CPU. Same enable-condition that nixos-hardware's
    # common-pc-laptop uses; inlined here so the role can stay scoped to
    # the laptop-enabled hosts without polluting desktop builds.
    services.tlp = {
      enable = lib.mkDefault (!config.services.power-profiles-daemon.enable);
      settings = {
        # Governor: full perf on AC, powersave on battery.
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        # EPP hint to the intel_pstate driver (Alder Lake-HX honors this).
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        # Turbo: on AC yes, on battery no (matches old auto-cpufreq policy).
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # WiFi power save on battery only; off on AC for stable latency.
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # BT audio dropouts: btusb runtime PM. Pairs with the modprobe option
        # below — that stops the driver, this stops TLP re-enabling it.
        USB_EXCLUDE_BTUSB = 1;
      };
    };

    # btusb enables runtime PM at probe time; TLP's exclusion only skips the
    # device, it never reverts it.
    boot.extraModprobeConfig = "options btusb enable_autosuspend=0";

    # Intel CNVi shares one antenna between WiFi and BT, so a 2.4GHz AP fights
    # BT audio. Docked on ethernet, WiFi is redundant — drop the radio.
    # Only NM-managed devices reach the dispatcher, so bridges/veths are moot.
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
