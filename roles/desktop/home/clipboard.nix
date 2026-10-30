{
  config,
  lib,
  ...
}: {
  services.cliphist = {
    enable = true;
    allowImages = true;
  };
}
