{
  config,
  lib,
  ...
}:
lib.mkIf (lib.elem "desktop-user" config.profiles) {
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}