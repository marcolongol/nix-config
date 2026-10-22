{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.harmony-sase;

  # osqueryi shim faking Device-Posture sentinel file checks; other queries go to real osquery. See spoofDpcFiles.
  realOsqueryi = "${cfg.package}/opt/Perimeter81/binaries/osquery/linux/osqueryi";
  osquerySpoof = pkgs.runCommand "harmony-sase-osquery-spoof" {} ''
    mkdir -p $out/binaries/osquery/linux
    cp ${pkgs.writeShellScript "osqueryi-spoof" ''
      # Non-matching queries delegate to real osquery with "$@".
      query="$*"
      for p in ${lib.escapeShellArgs cfg.spoofDpcFiles}; do
        if [[ "$query" == *"$p"* ]]; then
          printf '[{"path":"%s"}]\n' "$p"
          exit 0
        fi
      done
      exec ${realOsqueryi} "$@"
    ''} $out/binaries/osquery/linux/osqueryi
    chmod +x $out/binaries/osquery/linux/osqueryi
  '';

  # Overlay lowerdirs, highest priority first; the spoof dir only provides osqueryi.
  lowerdir =
    if cfg.spoofDpcFiles == []
    then "${cfg.package}/opt/Perimeter81"
    else "${osquerySpoof}:${cfg.package}/opt/Perimeter81";
in {
  options.programs.harmony-sase = {
    enable = lib.mkEnableOption "Check Point Harmony SASE (Perimeter81) VPN agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.harmony-sase;
      description = "The Harmony SASE package to use.";
    };

    spoofDpcFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["/dev/null/MacOS_Prohibited_on_TEOCO_VPN"];
      description = ''
        TEMPORARY workaround. File paths for which the agent's Device Posture
        Check (osquery file-existence rules) should report a match, forcing
        those checks to pass on this device. All other osquery posture queries
        still run against the real osquery. Intended only as a stopgap while a
        mis-scoped server-side posture profile is corrected; remove once fixed.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.package];

    # Agent binaries are unpatched pkg ELFs (patchelf corrupts them); nix-ld runs them,
    # including p81daemonhelper spawned directly by the GUI.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = cfg.package.runtimeLibs;

    # Agent drives VPN links via NetworkManager.
    networking.networkmanager.enable = true;
    networking.wireguard.enable = lib.mkDefault true;
    boot.kernelModules = ["wireguard"];

    # Agent expects a writable FHS /opt/Perimeter81; overlay it on the store tree.
    systemd.mounts = [
      {
        # Version stamped in What: overlayfs can't remount with a new lowerdir, so a changed What
        # forces a restart instead of a reload.
        what = "overlay-${cfg.package.version}";
        where = "/opt/Perimeter81";
        type = "overlay";
        options = lib.concatStringsSep "," [
          "lowerdir=${lowerdir}"
          "upperdir=/var/lib/perimeter81/upper"
          "workdir=/var/lib/perimeter81/work"
        ];
        wantedBy = ["multi-user.target"];
        # Drop default deps (Before=local-fs.target cycles with tmpfiles-setup); keep umount.target ones.
        after = ["systemd-tmpfiles-setup.service"];
        requires = ["systemd-tmpfiles-setup.service"];
        before = ["umount.target"];
        conflicts = ["umount.target"];
        unitConfig = {
          DefaultDependencies = false;
          RequiresMountsFor = "/var/lib";
        };
      }
    ];

    systemd.tmpfiles.rules = [
      # overlay backing dirs + mountpoint
      "d /var/lib/perimeter81 0755 root root -"
      "d /var/lib/perimeter81/upper 0755 root root -"
      "d /var/lib/perimeter81/work 0755 root root -"
      "d /opt/Perimeter81 0755 root root -"

      # GUI calls the helper by absolute /usr/bin path via sudo.
      "L+ /usr/bin/p81-helper-daemon - - - - ${cfg.package}/bin/harmony-sase-daemon"

      # Agent hardcodes these tool paths; NixOS lacks /sbin and /usr/sbin.
      "d /sbin 0755 root root -"
      "d /usr/sbin 0755 root root -"
      "L+ /sbin/ip - - - - ${lib.getExe' pkgs.iproute2 "ip"}"
      "L+ /usr/bin/wg-quick - - - - ${lib.getExe' pkgs.wireguard-tools "wg-quick"}"
      "L+ /usr/sbin/iptables - - - - ${lib.getExe' pkgs.iptables "iptables"}"
      "L+ /usr/sbin/ip6tables - - - - ${lib.getExe' pkgs.iptables "ip6tables"}"

      # Bundled wg-quick and helpers use #!/bin/bash.
      "L+ /bin/bash - - - - ${lib.getExe pkgs.bash}"
      "L+ /usr/bin/bash - - - - ${lib.getExe pkgs.bash}"

      # EnvironmentFile dir; 0700 because helper.env may hold secrets.
      "d /etc/perimeter81 0700 root root -"
      # Helper daemon runtime state.
      "d /etc/Perimeter81 0700 root root -"
    ];

    # Pin exact argument vectors for the multi-call helper (system-ctl start|stop, ipc <action>).
    # install-app/uninstall-app are deliberately not granted (root primitive); add new GUI sudo subcommands here.
    security.sudo.extraRules = let
      helper = "/usr/bin/p81-helper-daemon";
      args = [
        "system-ctl start"
        "system-ctl stop"
        "system-ctl ipc system-sleep"
        "system-ctl ipc system-resume"
      ];
    in [
      {
        users = ["ALL"];
        commands =
          [
            {
              command = "${helper} \"\"";
              options = ["NOPASSWD"];
            }
          ]
          ++ map (a: {
            command = "${helper} ${a}";
            options = ["NOPASSWD"];
          })
          args;
      }
    ];

    # Declared here because the GUI's install-app can't write units to read-only /etc/systemd/system.
    systemd.services.perimeter81helper = {
      description = "Perimeter81 helper service";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "NetworkManager.service" "opt-Perimeter81.mount"];
      requires = ["opt-Perimeter81.mount"];

      serviceConfig = {
        Type = "simple";
        EnvironmentFile = "-/etc/perimeter81/helper.env";
        ExecStart = "${cfg.package}/bin/harmony-sase-daemon";
        # Upstream stop semantics; without a timeout an ignored stop deadlocks switch-to-configuration.
        KillMode = "mixed";
        KillSignal = "SIGTERM";
        RestartKillSignal = "SIGTERM";
        TimeoutStopSec = "25s";
        # Block inherited NODE_OPTIONS injection into the root helper.
        Environment = ["NODE_OPTIONS="];
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # NM dispatcher hook: tells the helper about link changes, skipping agent interfaces.
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "50-perimeter81" ''
          case "$1" in
            tun0 | ipsec0 | p81) exit 0 ;;
          esac
          # 10.1.1.339: single dispatch event taking <iface> <event>.
          case "$2" in
            up | down | dhcp4-change | dhcp6-change)
              /usr/bin/p81-helper-daemon system-ctl ipc \
                network-manager-dispatch-event "$1" "$2"
              ;;
          esac
        '';
      }
    ];
  };
}
