# nix-darwin system configuration — professional macOS laptop.
#
# Here nix-darwin acts as a lightweight guest, managing Nix, shells, default preferences without trying to conform the whole machine.
#
# Apply: darwin-rebuild switch --flake .#work
{ pkgs, lib, unstable, ... }:

{
  # ── Nix daemon ──────────────────────────────────────────────────
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
    };
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 3; Minute = 0; };   # weekly, Sunday 03:00
      options = "--delete-older-than 30d";
    };
  };

  # ── Shell ───────────────────────────────────────────────────────
  # Register Nix-managed zsh in /etc/shells so it can be used as a
  # login shell.  The actual user shell is managed by MDM/Directory
  # Services — you may need to run `chsh -s /run/current-system/sw/bin/zsh`
  # once manually.
  programs.zsh.enable = true;

  # ── Keyboard & input ────────────────────────────────────────────
  system.defaults.NSGlobalDomain = {
    # Key repeat: fast repeat, short delay before repeat starts.
    KeyRepeat = 2;
    InitialKeyRepeat = 15;

    # Always show scroll bars.
    AppleShowScrollBars = "Always";
  };

  # ── Trackpad ────────────────────────────────────────────────────
  system.defaults.trackpad = {
    # Tap to click.
    Clicking = true;

    # Three-finger drag — select text or move windows by swiping
    # with three fingers (System Settings → Accessibility → Pointer
    # Control → Trackpad Options → Dragging style).
    TrackpadThreeFingerDrag = true;
  };

  # ── Dock ────────────────────────────────────────────────────────
  system.defaults.dock = {
    autohide = true;
    mru-spaces = false;             # don't rearrange Spaces by recent use
    show-recents = false;
  };

  # ── Finder ──────────────────────────────────────────────────────
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    FHIDeExtensionChangeWarning = false;
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  # ── Security ────────────────────────────────────────────────────
  # MDM controls FileVault, firewall, and most security policies.
  # We only set preferences that MDM typically leaves open.
  security.pam.services.sudo_local.touchIdAuth = true;

  # ── Hostname ────────────────────────────────────────────────────
  # Do NOT set networking.hostName or networking.computerName.

  # ── Users ─────────────────────────────
  # Do NOT declare users.users here. Home Manager manages the user
  # environment via the HM module wired in flake.nix.

  # ── Fonts ────────────────────────────────────────────────────────────
  # nix-darwin copies these into /Library/Fonts/Nix Fonts/ so that
  # macOS Core Text (and every native app) can discover them.
  fonts.packages = import ../fonts.nix { inherit unstable; };

  # Used by nix-darwin as a safety check. DO NOT change.
  system.stateVersion = 6; # !!! Have you read the comment above?
}
