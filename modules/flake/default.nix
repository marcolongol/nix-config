# flake-parts config beyond the omninix wiring in flake.nix.
{inputs, ...}: {
  # Proves the exported roles, profiles and modules work in other flakes.
  omninix.checks.portable = {
    enable = true;
    # Not converted yet (plan.md, phase 7b).
    exclude = [
      "nixosModules.cloudflare-tunnel"
    ];
    # What a consumer must bring for each piece.
    requires.roles.desktop = [inputs.stylix.nixosModules.stylix];
    scenarios.base.home.profiles = {
      common.enable = true;
      developer.enable = true;
      worker.enable = true;
    };
    scenarios.base.nixos = {
      roles.common.enable = true;
      roles.nfsClient = {
        enable = true;
        server = "nas.example:/export";
        shares = ["Media"];
      };
    };
    scenarios.desktop = {
      requires = [inputs.stylix.nixosModules.stylix];
      nixos = {pkgs, ...}: {
        roles.desktop.enable = true;
        # An inline scheme instead of a wallpaper skips stylix's palette build.
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/default-dark.yaml";
      };
    };
  };

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
