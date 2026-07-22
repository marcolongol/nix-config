{
  config,
  lib,
  pkgs,
  ...
}: lib.mkIf config.profiles.developer.enable {
  home.packages = with pkgs; [
    (python3.withPackages (ps:
      with ps; [
        ipython
        mypy
        pyright
        ruff
        pytest
        requests
        numpy
        pandas
        psutil
        types-psutil
        nbtlib
      ]))
  ];
}
