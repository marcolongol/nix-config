{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services."cloudflare-tunnel";
  # Caddy loopback port; cloudflared forwards all *.${domain} traffic here.
  caddyPort = 8080;
  # whoami smoke-test port; high to avoid user demo apps.
  whoamiPort = 8081;

  # User apps override the built-in whoami on name collision.
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
    # DynamicUser users don't exist at sops-nix activation; declare statically so chown resolves.
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

    sops.secrets.cloudflared-credentials = {
      mode = "0400";
      owner = "cloudflared";
      group = "cloudflared";
    };

    services.cloudflared = {
      enable = true;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = config.sops.secrets.cloudflared-credentials.path;
        ingress = {
          "*.${cfg.domain}" = "http://localhost:${toString caddyPort}";
        };
        default = "http_status:404";
      };
    };

    # Cloudflare terminates TLS; origin is plain HTTP on loopback.
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
          # Catch-all for subdomains not in the apps list.
          "http://" = {
            extraConfig = ''
              bind 127.0.0.1
              respond 404
            '';
          };
        };
    };

    # Smoke-test target, loopback only.
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
