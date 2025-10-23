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
}
