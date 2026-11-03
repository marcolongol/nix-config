# flake-parts config beyond the omninix wiring in flake.nix.
{inputs, ...}: {
  # Proves the exported roles, profiles and modules work in other flakes.
  omninix.checks.portable = {
    enable = true;
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
    scenarios.tunnel.nixos.services.cloudflare-tunnel = {
      enable = true;
      tunnelId = "00000000-0000-0000-0000-000000000000";
      credentialsFile = "/run/secrets/cloudflared-credentials";
      domain = "demo.example.com";
      apps.demo = 3000;
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
