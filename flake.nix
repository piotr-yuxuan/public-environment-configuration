{
  description = "NixOS fleet: C40C04 and future machines";

  inputs = {
    # Stable channel: system foundation
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Unstable channel: bleeding-edge CLI tools
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Declarative disk partitioning
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Secure Boot support
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific tweaks for known machines
    # nixos-hardware has no nixpkgs input of its own, so do NOT add
    # inputs.nixpkgs.follows here, it will produce a warning.
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager: user environment managed declaratively.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin: declarative macOS system configuration.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Starship gruvbox-rainbow preset (raw TOML, not a flake).
    # Refreshed automatically on `nix flake update`.
    starship-gruvbox-rainbow = {
      url = "https://starship.rs/presets/toml/gruvbox-rainbow.toml";
      flake = false;
    };

    # Practicalli Clojure deps.edn: community aliases for tools.deps.
    # `nix flake update` bumps to the latest main commit.
    practicalli-clojure-deps-edn = {
      url = "github:practicalli/clojure-deps-edn";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    disko,
    lanzaboote,
    nixos-hardware,
    home-manager,
    nix-darwin,
    starship-gruvbox-rainbow,
    practicalli-clojure-deps-edn,
    ...
  }: let
    # Unstable package set for x86_64-linux (C40C04)
    unstable = import nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    # Shared NixOS configuration
    # Everything here applies to ALL NixOS machines.
    sharedModule = {pkgs, ...}: {
      nixpkgs.config.allowUnfree = true;

      nix = {
        settings = {
          experimental-features = ["nix-command" "flakes"];
          auto-optimise-store = true;
        };
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };

      time.timeZone = "Europe/Paris";
      i18n.defaultLocale = "en_US.UTF-8";

      # System packages from stable
      environment.systemPackages = with pkgs; [
        vim
        git
        sbctl # for debugging Secure Boot after install
        btrfs-progs
      ];

      networking.networkmanager.enable = true;

      # Firewall
      # Deny all inbound by default. Open ports per-host as needed.
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [];
        allowedUDPPorts = [];
      };

      # SSH is explicitly disabled fleet-wide. Enable per-host only if needed,
      # e.g. services.openssh.enable = lib.mkForce true; in hosts/<name>.nix.
      services.openssh.enable = false;

      # Nix daemon access
      # Only wheel users may talk to the Nix daemon (build, fetch, etc.).
      nix.settings.allowed-users = ["@wheel"];
      # Scoped to caocoa rather than @wheel so that future non-owner
      # accounts cannot push arbitrary store paths bypassing signatures.
      nix.settings.trusted-users = ["root" "caocoa"];

      # sudo: restrict the binary to wheel group members
      security.sudo.execWheelOnly = true;

      # User accounts
      # Immutable users: passwd/useradd/userdel are no-ops.
      # Passwords can ONLY be changed by updating the hashedPasswordFile
      # and running nixos-rebuild. This prevents silent drift.
      users.mutableUsers = false;

      users.users.caocoa = {
        isNormalUser = true;
        description = "Caocoa";
        home = "/home/caocoa";
        shell = pkgs.zsh;
        extraGroups = ["wheel" "networkmanager" "video" "audio"];
        hashedPasswordFile = "/etc/secrets/caocoa-password";
      };

      # Zsh must be enabled at system level so NixOS adds it to /etc/shells.
      # User-level config (plugins, prompt, etc.) is handled by Home Manager.
      programs.zsh.enable = true;
    };

    # Home Manager (NixOS module)
    # Wires Home Manager for user caocoa on NixOS hosts.
    # Per-host HM overrides live in home/<host>.nix; shared config in
    # home/base.nix uses the same pattern as the standalone work config.
    homeManagerModule = {...}: {
      home-manager = {
        useGlobalPkgs = true; # reuse the system nixpkgs instance
        useUserPackages = true; # install into /etc/profiles/per-user
        backupFileExtension = "hm-backup";
        extraSpecialArgs = {inherit unstable starship-gruvbox-rainbow practicalli-clojure-deps-edn;};

        users.caocoa = {
          imports =
            [./home/base.nix]
            ++ (
              if builtins.pathExists ./home/C40C04.nix
              then [./home/C40C04.nix]
              else []
            );
          home.username = "caocoa";
          home.homeDirectory = "/home/caocoa";
          home.stateVersion = "25.11";
        };
      };
    };
  in {
    nixosConfigurations =
      {}
      // (
        if builtins.pathExists ./hosts/C40C04.nix
        then {
          C40C04 = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit unstable;};
            modules = [
              sharedModule
              disko.nixosModules.disko
              ./disko-config.nix
              lanzaboote.nixosModules.lanzaboote
              ./hardware-configuration.nix

              # Framework 16 AMD 7040 hardware profile
              nixos-hardware.nixosModules.framework-16-7040-amd

              # Home Manager: user caocoa (home/shared.nix + home/C40C04.nix)
              home-manager.nixosModules.home-manager
              homeManagerModule

              ./hosts/C40C04.nix
            ];
          };
        }
        else {}
      );

    # macOS machines (nix-darwin)
    # Usage:  darwin-rebuild switch --flake .#work --impure
    darwinConfigurations = {
      work = let
        unstable-darwin = import nixpkgs-unstable {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        # Read the current macOS username at eval time.
        # Requires --impure so Nix can access environment variables.
        # Falls back to "nobody" in pure mode so `nix flake check` can
        # parse the structure without --impure.
        envUser = builtins.getEnv "USER";
        darwinUser =
          if envUser != ""
          then envUser
          else "nobody";
        darwinHome = "/Users/${darwinUser}";
      in
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {unstable = unstable-darwin;};
          modules = [
            ./hosts/work.nix

            home-manager.darwinModules.home-manager
            {
              nixpkgs.config.allowUnfree = true;

              # Declare the user so nix-darwin and Home Manager can
              # derive home directory and shell automatically.
              system.primaryUser = darwinUser;
              users.users.${darwinUser}.home = darwinHome;

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "hm-backup";
                extraSpecialArgs = {
                  unstable = unstable-darwin;
                  inherit starship-gruvbox-rainbow practicalli-clojure-deps-edn;
                };

                users.${darwinUser} = {
                  imports = [./home/base.nix ./home/work.nix];
                  home.stateVersion = "25.11";
                };
              };
            }
          ];
        };
    };
  };
}
