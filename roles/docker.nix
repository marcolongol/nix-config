{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf (lib.elem "docker" config.roles) {
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    logDriver = "journald";
  };

  # Wildcard DNS for local cluster ingress (*.k3d.local -> 127.0.0.1)
  # Uses a minimal dnsmasq bound to 127.0.0.55 for .k3d.local only,
  # with resolved forwarding that domain to it — preserving DNSSEC and VPN split-DNS.
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNS = "127.0.0.55";
        Domains = "~k3d.local";
      };
    };
  };

  # Assign 127.0.0.55 explicitly to loopback so dnsmasq can bind to it
  # (127.0.0.53 and 127.0.0.54 are reserved by systemd-resolved)
  networking.interfaces.lo.ipv4.addresses = [
    {
      address = "127.0.0.55";
      prefixLength = 8;
    }
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = "127.0.0.55";
      bind-interfaces = true;
      address = "/.k3d.local/127.0.0.1";
    };
  };
}
