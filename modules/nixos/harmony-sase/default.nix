{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.harmony-sase;

  # Shim osqueryi that fakes Device-Posture file-existence checks for the listed
  # sentinel paths and delegates every other query to the real osquery, so all
  # other posture rules still evaluate truthfully. Shadows the bundled osqueryi
  # via a higher-priority overlay lowerdir (below). See spoofDpcFiles.
  realOsqueryi = "${cfg.package}/opt/Perimeter81/binaries/osquery/linux/osqueryi";
  osquerySpoof = pkgs.runCommand "harmony-sase-osquery-spoof" {} ''
    mkdir -p $out/binaries/osquery/linux
    cp ${pkgs.writeShellScript "osqueryi-spoof" ''
      # $* (args joined) is sufficient: we only substring-match the distinctive
      # sentinel path. Non-matching queries delegate with "$@" to preserve arg
      # boundaries for the real osquery.
      query="$*"
      for p in ${lib.escapeShellArgs cfg.spoofDpcFiles}; do
        if [[ "$query" == *"$p"* ]]; then
          # Minimal `osqueryi --json` output: pretend the sentinel file exists.
          printf '[{"path":"%s"}]\n' "$p"
          exit 0
        fi
      done
      exec ${realOsqueryi} "$@"
    ''} $out/binaries/osquery/linux/osqueryi
    chmod +x $out/binaries/osquery/linux/osqueryi
  '';

  # Overlay lowerdirs, highest priority first. The spoof dir only contributes
  # binaries/osquery/linux/osqueryi; everything else falls through to the agent.
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

    # The agent's GUI + helper binaries are unpatched generic/pkg ELFs. nix-ld
    # supplies /lib64/ld-linux so they run unmodified (patchelf corrupts the
    # vercel/pkg payloads). The library set covers p81daemonhelper, which the
    # GUI spawns directly without going through our wrappers.
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = cfg.package.runtimeLibs;

    # The agent connects over WireGuard / OpenVPN and drives the link via
    # NetworkManager (its dispatcher hook fires on tun0/ipsec0/p81 changes).
    networking.networkmanager.enable = true;
    networking.wireguard.enable = lib.mkDefault true;
    boot.kernelModules = ["wireguard"];

    # The agent assumes a writable FHS install at /opt/Perimeter81 and spawns
    # its own siblings (p81daemonhelper, osquery) by that absolute path, while
    # also writing state into it (mkdir /opt/Perimeter81/yarkon). Present the
    # read-only store tree as a writable overlay so both work.
    systemd.mounts = [
      {
        what = "overlay";
        where = "/opt/Perimeter81";
        type = "overlay";
        options = lib.concatStringsSep "," [
          "lowerdir=${lowerdir}"
          "upperdir=/var/lib/perimeter81/upper"
          "workdir=/var/lib/perimeter81/work"
        ];
        wantedBy = ["multi-user.target"];
        after = ["systemd-tmpfiles-setup.service"];
        requires = ["systemd-tmpfiles-setup.service"];
        unitConfig.RequiresMountsFor = "/var/lib";
      }
    ];

    systemd.tmpfiles.rules = [
      # overlay backing dirs + mountpoint
      "d /var/lib/perimeter81 0755 root root -"
      "d /var/lib/perimeter81/upper 0755 root root -"
      "d /var/lib/perimeter81/work 0755 root root -"
      "d /opt/Perimeter81 0755 root root -"

      # GUI invokes the helper by ABSOLUTE path via sudo; NixOS has no populated
      # /usr/bin, so symlink the nix-ld/PATH-wrapped helpers in.
      "L+ /usr/bin/p81-helper-daemon - - - - ${cfg.package}/bin/harmony-sase-daemon"
      "L+ /usr/bin/p81-helper-daemon-creator - - - - ${cfg.package}/bin/harmony-sase-daemon-creator"

      # Tools the agent calls by absolute path (hardcoded in the binaries).
      # NixOS lacks /sbin and /usr/sbin, so create them before symlinking in.
      "d /sbin 0755 root root -"
      "d /usr/sbin 0755 root root -"
      "L+ /sbin/ip - - - - ${lib.getExe' pkgs.iproute2 "ip"}"
      "L+ /usr/bin/wg-quick - - - - ${lib.getExe' pkgs.wireguard-tools "wg-quick"}"
      "L+ /usr/sbin/iptables - - - - ${lib.getExe' pkgs.iptables "iptables"}"
      "L+ /usr/sbin/ip6tables - - - - ${lib.getExe' pkgs.iptables "ip6tables"}"

      # The bundled wg-quick (and the agent's troubleshooting helper) are
      # #!/bin/bash scripts; NixOS ships neither /bin/bash nor /usr/bin/bash.
      "L+ /bin/bash - - - - ${lib.getExe pkgs.bash}"
      "L+ /usr/bin/bash - - - - ${lib.getExe pkgs.bash}"

      # daemon-creator's EnvironmentFile path (lowercase). 0700: helper.env may
      # hold connection secrets and is only read by the root helper service.
      "d /etc/perimeter81 0700 root root -"
      # helper daemon runtime state (capital P — /etc/Perimeter81/{net,swg,...}).
      "d /etc/Perimeter81 0700 root root -"
    ];

    # Upstream installs a blanket `ALL ALL=NOPASSWD: /usr/bin/p81-helper-daemon
    # {,-creator}` with no argument spec — i.e. any user may run the helper as
    # root with ANY arguments. We keep `users = ALL` (shared machines need it)
    # but pin the exact subcommands the agent dispatches, so a future upstream
    # subcommand can't become a free root primitive. The GUI only invokes
    # `start` via sudo; the rest are enumerated to avoid breaking lifecycle
    # (stop/restart/status), the sleep hooks (system-{sleep,resume}) and the
    # installer paths. NOTE: a NEW subcommand in a future agent version that the
    # GUI calls via sudo must be added here.
    security.sudo.extraRules = let
      creator = "/usr/bin/p81-helper-daemon-creator";
      subcommands = [
        "start"
        "stop"
        "restart"
        "status"
        "enable"
        "disable"
        "install"
        "uninstall"
        "system-sleep"
        "system-resume"
      ];
    in [
      {
        users = ["ALL"];
        commands =
          # The bare daemon, no arguments.
          [
            {
              command = "/usr/bin/p81-helper-daemon \"\"";
              options = ["NOPASSWD"];
            }
          ]
          # daemon-creator, one entry per known subcommand.
          ++ map (sub: {
            command = "${creator} ${sub}";
            options = ["NOPASSWD"];
          })
          subcommands;
      }
    ];

    # Privileged helper service. Declared here instead of letting the GUI run
    # `daemon-creator install` (which would try to write a unit into the
    # read-only Nix-managed /etc/systemd/system). Template taken verbatim from
    # the daemon-creator binary's embedded unit.
    systemd.services.perimeter81helper = {
      description = "Perimeter81 helper service";
      wantedBy = ["multi-user.target"];
      after = ["network.target" "NetworkManager.service" "opt-Perimeter81.mount"];
      requires = ["opt-Perimeter81.mount"];

      serviceConfig = {
        Type = "simple";
        EnvironmentFile = "-/etc/perimeter81/helper.env";
        ExecStart = "${cfg.package}/bin/harmony-sase-daemon";
        KillMode = "process";
        Restart = "on-failure";
        RestartSec = 1;
      };
    };

    # NetworkManager dispatcher hook — notifies the helper of link up/down so it
    # can react to underlying network changes (replicated from after-install.sh,
    # skipping the agent's own tun0/ipsec0/p81 interfaces).
    networking.networkmanager.dispatcherScripts = [
      {
        type = "basic";
        source = pkgs.writeShellScript "50-perimeter81" ''
          case "$1" in
            tun0 | ipsec0 | p81) exit 0 ;;
          esac
          case "$2" in
            up)   /usr/bin/p81-helper-daemon-creator network-interface-up ;;
            down) /usr/bin/p81-helper-daemon-creator network-interface-down ;;
          esac
        '';
      }
    ];
  };
}
