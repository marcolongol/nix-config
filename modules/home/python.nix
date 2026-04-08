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
        black
        flake8
        isort
        mypy
        pylint
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
