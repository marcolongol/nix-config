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

    omninix.persistence.directories = ["/var/lib/docker"];
  };
}
