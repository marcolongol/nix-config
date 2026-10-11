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
    # TLP is the canonical laptop power-management daemon. Tunes CPU, disk
    # APM, USB autosuspend, PCIe ASPM, WiFi power save — auto-cpufreq only
    # touched the CPU. Same enable-condition that nixos-hardware's
    # common-pc-laptop uses; inlined here so the role can stay scoped to
    # the laptop-enabled hosts without polluting desktop builds.
    services.tlp = {
      enable = lib.mkDefault (!config.services.power-profiles-daemon.enable);
      settings = {
        # Governor: powersave on both. On intel_pstate "powersave" still
        # boosts to full turbo on demand — it only lets the cores drop back
        # down between wakeups, which "performance" refuses to do. With k3s
        # ticking in the background that meant ~3.5 GHz around the clock and
        # 24 min of logged package throttling. EPP below still biases toward
        # performance on AC, so loaded work is unaffected.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
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

    # No upower means no low-battery warning and no critical-battery action:
    # the pack just runs flat and the machine dies mid-write (it did, twice —
    # Oct 10 02:00 and Oct 11 11:28). Shut down cleanly at the critical
    # threshold instead; PowerOff over Hibernate because resume is unproven
    # (no resumeDevice set, nvidia in the mix).
    services.upower = {
      enable = true;
      criticalPowerAction = "PowerOff";
    };

    # upower only *acts* at percentageAction; nothing on Hyprland warns you
    # before that. poweralertd turns upower's warning-level changes into
    # notifications. Lives with the upower block rather than in the host so a
    # second laptop gets it for free.
    home-manager.users = lib.genAttrs activeUsers (_: {
      services.poweralertd = {
        enable = true;
        # -i line-power: the ACAD on/offline alert duplicates the battery's own
        #   charging/discharging one, so it fired twice per unplug.
        # -s: no replay of current state at login.
        extraArgs = ["-s" "-i" "line-power"];
      };
    });

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
