{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.surfshark;

  # GJS scripts use GObject introspection — typelib files must be reachable.
  # Both daemons import at minimum: NM, GLib, GObject, Gio, Notify, Secret.
  giTypelibPath = lib.makeSearchPath "lib/girepository-1.0" [
    pkgs.networkmanager
    pkgs.glib
    pkgs.libnotify
    pkgs.libsecret
    pkgs.gsettings-desktop-schemas
  ];
in
{
  options.programs.surfshark = {
    enable = lib.mkEnableOption "Surfshark VPN";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.surfshark;
      description = "The Surfshark package to use.";
    };

    enableKillSwitch = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to allow Surfshark's iptables-based kill switch.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # NetworkManager is required by Surfshark for VPN connection management
    networking.networkmanager.enable = true;

    # Surfshark uses WireGuard — load the kernel module and enable NM integration
    networking.wireguard.enable = lib.mkDefault true;
    boot.kernelModules = [ "wireguard" ];

    # Allow Surfshark's daemons to manage iptables rules (kill switch)
    security.wrappers = lib.mkIf cfg.enableKillSwitch {
      iptables = {
        source = "${pkgs.iptables}/bin/iptables";
        capabilities = "cap_net_admin+ep";
        owner = "root";
        group = "root";
      };
      ip6tables = {
        source = "${pkgs.iptables}/bin/ip6tables";
        capabilities = "cap_net_admin+ep";
        owner = "root";
        group = "root";
      };
    };

    environment.variables.GI_TYPELIB_PATH = giTypelibPath;

    # System-scope daemon (surfsharkd2) — manages network/VPN operations.
    # The .js files use #!/usr/bin/gjs; we invoke gjs explicitly so the shebang
    # path doesn't need to exist outside the FHS wrapper environment.
    systemd.services.surfsharkd2 = {
      description = "Surfshark System Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "NetworkManager.service"
      ];

      environment.GI_TYPELIB_PATH = giTypelibPath;

      serviceConfig = {
        ExecStart = "${pkgs.gjs}/bin/gjs ${cfg.package.data}/opt/Surfshark/resources/dist/resources/surfsharkd2.js";
        Restart = "on-failure";
        RestartSec = 5;
        # Surfshark's own hardening options (from upstream .deb postinst)
        IPAddressDeny = "any";
        RestrictRealtime = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        RestrictSUIDSGID = true;
      };
    };

    # User-scope daemon (surfsharkd) — manages UI/IPC with the Electron frontend
    systemd.user.services.surfsharkd = {
      description = "Surfshark User Daemon";
      wantedBy = [ "default.target" ];

      environment.GI_TYPELIB_PATH = giTypelibPath;

      serviceConfig = {
        ExecStart = "${pkgs.gjs}/bin/gjs ${cfg.package.data}/opt/Surfshark/resources/dist/resources/surfsharkd.js";
        Restart = "on-failure";
        RestartSec = 5;
        IPAddressDeny = "any";
        RestrictRealtime = true;
        ProtectKernelTunables = true;
        ProtectSystem = "full";
        RestrictSUIDSGID = true;
      };
    };
  };
}
