{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    impermanence.url = "github:nix-community/impermanence";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixievim = {
      url = "github:marcolongol/nixievim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code plugins/skills: plain repos (no flake.nix), tracked as inputs
    # so `nix flake update` bumps them instead of hand-edited rev+hash pairs.
    claude-ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };

    claude-ui-ux-pro-max = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };

    claude-code-upstream = {
      url = "github:anthropics/claude-code";
      flake = false;
    };

    claude-angular-skills = {
      url = "github:oguzhan18/angular-ecosystem-skills";
      flake = false;
    };
  };

  outputs = {
    self,
    systems,
    flake-parts,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = import systems;
      _module.args = {inherit inputs;};
      imports = [
        ./modules/flake
      ];
      flake = {inherit self;};
    };
}
