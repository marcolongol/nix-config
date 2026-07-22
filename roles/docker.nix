{
  config,
  lib,
  ...
}: {
  options.roles.docker.enable = lib.mkEnableOption "Docker container runtime";

  config = lib.mkIf config.roles.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
      logDriver = "journald";
    };

    persistentFolders = ["/var/lib/docker"];

    # Allow inbound traffic from Docker bridge networks (br+) to host services.
    # Required for k3d pods to reach host-local servers (e.g. Prefect UI at port 4200).
    networking.firewall.extraInputRules = ''
      iifname "br*" accept
    '';
  };
}
