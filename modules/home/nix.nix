{pkgs, ...}: {
  home.packages = with pkgs; [
    alejandra
    nixd
    deadnix
    statix
    nh
  ];
}
