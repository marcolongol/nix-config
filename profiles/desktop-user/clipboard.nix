{
  config,
  lib,
  ...
}:
lib.mkIf config.profiles.desktopUser.enable {
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}