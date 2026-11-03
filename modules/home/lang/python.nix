{
  config,
  lib,
  pkgs,
  ...
}: {
  options.lang.python.enable = lib.mkEnableOption "Python toolchain";

  config = lib.mkIf config.lang.python.enable {
    home.packages = with pkgs; [
      (python3.withPackages (ps:
        with ps; [
          ipython
          mypy
          pyright
          ruff
          openpyxl
          pytest
          requests
          numpy
          pandas
          psutil
          types-psutil
          nbtlib
        ]))
    ];
  };
}
