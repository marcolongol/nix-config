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

    # Let Docker bridge networks (br+) reach host services (k3d pods -> Prefect UI :4200).
    networking.firewall.extraInputRules = ''
      iifname "br*" accept
    '';
  };
}
