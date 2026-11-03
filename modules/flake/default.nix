# flake-parts config beyond the omninix wiring in flake.nix.
{
  # Proves the exported roles, profiles and modules work in other flakes.
  omninix.checks.portable = {
    enable = true;
    # Not converted yet (plan.md, phases 6–7b).
    exclude = [
      "roles.desktop"
      "profiles.common"
      "homeModules.lang"
      "homeModules.tmux"
      "homeModules.starship"
      "homeModules.zsh"
      "nixosModules.cloudflare-tunnel"
    ];
    scenarios.base.nixos = {
      roles.common.enable = true;
      roles.nfsClient = {
        enable = true;
        server = "nas.example:/export";
        shares = ["Media"];
      };
    };
  };

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
