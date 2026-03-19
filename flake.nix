{
  description = "NixOS fleet — C40C04 and future machines";

  inputs = {
    # Stable channel — system foundation
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Unstable channel — bleeding-edge CLI tools
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
    # nixos-hardware has no nixpkgs input of its own — do NOT add
    # inputs.nixpkgs.follows here, it will produce a warning.
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Home Manager — user environment managed declaratively.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-darwin — declarative macOS system configuration.
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Starship gruvbox-rainbow preset (raw TOML, not a flake).
    # Refreshed automatically on `nix flake update`.
    starship-gruvbox-rainbow = {
      url = "https://starship.rs/presets/toml/gruvbox-rainbow.toml";
      flake = false;
    };

    # Practicalli Clojure deps.edn — community aliases for tools.deps.
    # `nix flake update` bumps to the latest main commit.
    practicalli-clojure-deps-edn = {
      url = "github:practicalli/clojure-deps-edn";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, disko, lanzaboote, nixos-hardware, home-manager, nix-darwin, starship-gruvbox-rainbow, practicalli-clojure-deps-edn, ... }:
  let
    # ── Unstable package set for x86_64-linux (C40C04) ───────────────
    unstable = import nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };

    # ── Shared NixOS configuration ──────────────────────────────────
    # Everything here applies to ALL NixOS machines.
    sharedModule = { pkgs, ... }: {
      nixpkgs.config.allowUnfree = true;

      nix = {
        settings = {
          experimental-features = [ "nix-command" "flakes" ];
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
        sbctl        # for debugging Secure Boot after install
        btrfs-progs
      ];

      networking.networkmanager.enable = true;

      # ── Firewall ─────────────────────────────────────────────────────
      # Deny all inbound by default. Open ports per-host as needed.
      networking.firewall = {
        enable = true;
        allowedTCPPorts = [ ];
        allowedUDPPorts = [ ];
      };

      # SSH is explicitly disabled fleet-wide. Enable per-host only if needed,
      # e.g. services.openssh.enable = lib.mkForce true; in hosts/<name>.nix.
      services.openssh.enable = false;

      # ── Nix daemon access ─────────────────────────────────────────
      # Only wheel users may talk to the Nix daemon (build, fetch, etc.).
      nix.settings.allowed-users = [ "@wheel" ];
      nix.settings.trusted-users = [ "root" "@wheel" ];

      # ── User accounts ─────────────────────────────────────────────
      # Immutable users: passwd/useradd/userdel are no-ops.
      # Passwords can ONLY be changed by updating the hashedPasswordFile
      # and running nixos-rebuild. This prevents silent drift.
      users.mutableUsers = false;

      users.users.caocoa = {
        isNormalUser = true;
        home = "/home/caocoa";
        shell = pkgs.zsh;
        extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
        hashedPasswordFile = "/etc/secrets/caocoa-password";
      };

      # Zsh must be enabled at system level so NixOS adds it to /etc/shells.
      # User-level config (plugins, prompt, etc.) is handled by Home Manager.
      programs.zsh.enable = true;
    };

    # ── Home Manager (NixOS module) ──────────────────────────────────
    # Wires Home Manager for user caocoa on NixOS hosts.
    # Per-host HM overrides live in home/<host>.nix; shared config in
    # home/base.nix — the same pattern used by the standalone work config.
    homeManagerModule = { ... }: {
      home-manager = {
        useGlobalPkgs       = true;   # reuse the system nixpkgs instance
        useUserPackages     = true;   # install into /etc/profiles/per-user
        backupFileExtension = "hm-backup";
        extraSpecialArgs    = { inherit unstable starship-gruvbox-rainbow practicalli-clojure-deps-edn; };

        users.caocoa = {
          imports = [ ./home/base.nix ]
            ++ (if builtins.pathExists ./home/C40C04.nix then [ ./home/C40C04.nix ] else [ ]);
          home.username      = "caocoa";
          home.homeDirectory = "/home/caocoa";
          home.stateVersion  = "25.11";
        };
      };
    };

  in {
    nixosConfigurations = {

      C40C04 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit unstable; };
        modules = [
          sharedModule
          disko.nixosModules.disko
          ./disko-config.nix
          lanzaboote.nixosModules.lanzaboote
          ./hardware-configuration.nix

          # Framework 16 AMD 7040 hardware profile
          nixos-hardware.nixosModules.framework-16-7040-amd

          # Home Manager — user caocoa (home/shared.nix + home/C40C04.nix)
          home-manager.nixosModules.home-manager
          homeManagerModule

          ./hosts/C40C04.nix
        ];
      };

      # Future: work laptop
      # work-laptop = nixpkgs.lib.nixosSystem { ... };
    };

    # ── macOS machines (nix-darwin) ──────────────────────────────────
    # Usage:  darwin-rebuild switch --flake .#work
    darwinConfigurations = {
      work = let
        unstable-darwin = import nixpkgs-unstable {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
      in nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { unstable = unstable-darwin; };
        modules = [
          ./hosts/work.nix

          home-manager.darwinModules.home-manager
          {
            nixpkgs.config.allowUnfree = true;

            home-manager = {
              useGlobalPkgs       = true;
              useUserPackages     = true;
              backupFileExtension = "hm-backup";
              extraSpecialArgs = { unstable = unstable-darwin; inherit starship-gruvbox-rainbow practicalli-clojure-deps-edn; };

              # TODO: Replace with your corporate username (run `whoami`).
              users.example = {
                imports = [ ./home/base.nix ./home/work.nix ];
                home.username      = "example";
                home.homeDirectory = "/Users/example";
                home.stateVersion  = "25.11";
              };
            };
          }
        ];
      };
    };
  };
}
