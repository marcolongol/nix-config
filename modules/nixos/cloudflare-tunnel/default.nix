{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services."cloudflare-tunnel";
  # Caddy listens here on loopback only. cloudflared forwards all
  # *.${domain} traffic into this port; Caddy fans out by Host header.
  caddyPort = 8080;
  # Internal port for the bundled whoami smoke test. Chosen high to
  # avoid clashing with user demo apps (which typically grab 3000-8000).
  whoamiPort = 8081;

  # User apps + (optionally) the built-in whoami entry. User wins on
  # name collision so a real `apps.whoami = N;` always overrides the
  # smoke test.
  effectiveApps =
    (lib.optionalAttrs cfg.whoami.enable {whoami = whoamiPort;})
    // cfg.apps;
in {
  options.services.cloudflare-tunnel = {
    enable = lib.mkEnableOption "Cloudflare tunnel + Caddy wildcard router";

    tunnelId = lib.mkOption {
      type = lib.types.str;
      description = ''
        UUID returned by `cloudflared tunnel create <name>`. The matching
        credentials JSON must be stored under the `cloudflared-credentials`
        sops key in this host's secrets file.
      '';
    };

    domain = lib.mkOption {
      type = lib.types.str;
      example = "nixos-lt.marcolongo.dev";
      description = ''
        Base domain. Each app is served at `<name>.<domain>`. A wildcard
        `*.<domain>` CNAME pointing at `<tunnelId>.cfargotunnel.com` must
        exist in Cloudflare DNS (one-time manual step).
      '';
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf lib.types.port;
      default = {};
      example = {
        demo = 3000;
        api = 8000;
      };
      description = ''
        Demo apps to expose. Each entry `name = port` maps
        `<name>.<domain>` to `http://127.0.0.1:<port>`. Unmatched
        subdomains return 404.
      '';
    };

    whoami.enable = lib.mkEnableOption ''
      bundled Traefik whoami smoke-test service. Exposes
      `whoami.<domain>` returning os info and request headers — useful
      to confirm the full chain (Cloudflare edge → tunnel → Caddy →
      origin) works without standing up your own app
    '';
  };

  config = lib.mkIf cfg.enable {
    # services.cloudflared runs with `DynamicUser=true`, meaning the
    # `cloudflared` user only exists while the unit is active. sops-nix
    # chowns secrets during activation (before the unit starts), so the
    # name must resolve in /etc/passwd. Declare the user statically and
    # opt the unit out of DynamicUser to keep the names stable.
    users.users.cloudflared = {
      isSystemUser = true;
      group = "cloudflared";
    };
    users.groups.cloudflared = {};

    systemd.services."cloudflared-tunnel-${cfg.tunnelId}".serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "cloudflared";
      Group = "cloudflared";
    };

    # Tunnel credentials JSON, decrypted at boot under /run/secrets.
    sops.secrets.cloudflared-credentials = {
      mode = "0400";
      owner = "cloudflared";
      group = "cloudflared";
    };

    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = config.sops.secrets.cloudflared-credentials.path;
        # Single wildcard rule — host-header routing happens in Caddy below.
        ingress = {
          "*.${cfg.domain}" = "http://localhost:${toString caddyPort}";
        };
        default = "http_status:404";
      };
    };

    # Cloudflare terminates TLS at the edge, so the origin proxy is plain
    # HTTP bound to loopback only. No inbound public ports required —
    # cloudflared maintains an outbound persistent connection to Cloudflare.
    services.caddy = {
      enable = true;
      globalConfig = ''
        auto_https off
        http_port ${toString caddyPort}
      '';
      virtualHosts =
        (lib.mapAttrs' (
            name: port:
              lib.nameValuePair "http://${name}.${cfg.domain}" {
                extraConfig = ''
                  bind 127.0.0.1
                  reverse_proxy http://127.0.0.1:${toString port}
                '';
              }
          )
          effectiveApps)
        // {
          # Catch-all for *.${domain} subdomains not in the apps list.
          # Without this, Caddy would serve its default "no site" page.
          "http://" = {
            extraConfig = ''
              bind 127.0.0.1
              respond 404
            '';
          };
        };
    };

    # Built-in smoke test target. Runs as a dynamic user, loopback-only
    # (whoami's default is 0.0.0.0 but Caddy is the only thing that
    # talks to it via 127.0.0.1).
    systemd.services.whoami = lib.mkIf cfg.whoami.enable {
      description = "Traefik whoami (cloudflare-tunnel smoke test)";
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      serviceConfig = {
        ExecStart = "${pkgs.whoami}/bin/whoami -port ${toString whoamiPort}";
        DynamicUser = true;
        Restart = "on-failure";
      };
    };
  };
}
