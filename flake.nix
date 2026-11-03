{
  description = "A very basic flake";

  inputs = {
    # Base: everything else follows these.
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    systems.url = "github:nix-systems/default/future-26.11";

    # Followed by omninix and other inputs.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omninix = {
      url = "github:marcolongol/omninix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        home-manager.follows = "home-manager";
        sops-nix.follows = "sops-nix";
        systems.follows = "systems";
      };
    };

    # Leaves on nixpkgs + home-manager.
    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    # Leaves on nixpkgs.
    comin = {
      url = "github:nlewo/comin";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      };
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixievim = {
      url = "github:marcolongol/nixievim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code plugins/skills: plain repos without flake.nix.
    claude-angular-skills = {
      url = "github:oguzhan18/angular-ecosystem-skills";
      flake = false;
    };

    claude-code-upstream = {
      url = "github:anthropics/claude-code";
      flake = false;
    };

    claude-ponytail = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };

    claude-ui-ux-pro-max = {
      url = "github:nextlevelbuilder/ui-ux-pro-max-skill";
      flake = false;
    };
  };

  outputs = {
    flake-parts,
    omninix,
    systems,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [omninix.flakeModules.default];

      systems = import systems;

      omninix = {
        hostsDir = ./hosts;
        rolesDir = ./roles;
        usersDir = ./users;
        profilesDir = ./profiles;
        nixosModulesDir = ./modules/nixos;
        homeManagerModulesDir = ./modules/home;
        overlaysDir = ./overlays;
        packagesDir = ./packages;
        secretsPath = ./secrets;
        allowUnfree = true;
        # Picked by name, so roles omninix adds later don't appear here unasked.
        extraRoles = {
          impermanent = omninix.roles.impermanent;
        };
        # Third-party modules, imported into every host / every user. They're
        # inert until configured. impermanence must be on every host: omninix
        # maps omninix.persistence into its home.persistence for all users.
        extraNixosModules = {
          disko = inputs.disko.nixosModules.disko;
          impermanence = inputs.impermanence.nixosModules.impermanence;
          stylix = inputs.stylix.nixosModules.stylix;
          comin = inputs.comin.nixosModules.comin;
          nix-index = inputs.nix-index-database.nixosModules.nix-index;
        };
        extraHomeManagerModules = {
          nixievim = inputs.nixievim.homeManagerModules.default;
          zen-browser = inputs.zen-browser.homeModules.beta;
        };
      };

      perSystem = {pkgs, ...}: {
        formatter = pkgs.alejandra;
      };
    };
}
