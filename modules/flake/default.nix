# flake-parts config beyond the omninix wiring in flake.nix.
{
  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
