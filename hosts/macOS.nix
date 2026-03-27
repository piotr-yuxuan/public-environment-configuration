# nix-darwin system configuration for a professional macOS laptop.
#
# Here nix-darwin acts as a lightweight guest, managing Nix, shells, default preferences without trying to conform the whole machine.
#
# Apply: darwin-rebuild switch --flake .#macOS-arm64 --impure  (or .#macOS-x86_64)
{
  pkgs,
  lib,
  unstable,
  ...
}: {
  # Nix daemon
  nix.optimise.automatic = true;
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # auto-optimise-store removed: known to corrupt the store.
      # Scoped to the machine owner so future accounts cannot push
      # arbitrary store paths bypassing signature verification.
      trusted-users = let
        user = builtins.getEnv "USER";
      in
        ["root"]
        ++ (
          if user != ""
          then [user]
          else []
        );
    };
    gc = {
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 3;
        Minute = 0;
      }; # weekly, Sunday 03:00
      options = "--delete-older-than 30d";
    };
  };

  # Shell
  # Register Nix-managed zsh in /etc/shells so it can be used as a
  # login shell.  The actual user shell is managed by MDM/Directory
  # Services: you may need to run `chsh -s /run/current-system/sw/bin/zsh`
  # once manually.
  programs.zsh.enable = true;

  # Keyboard & input
  system.defaults.NSGlobalDomain = {
    # Key repeat: fast repeat, short delay before repeat starts.
    KeyRepeat = 2;
    InitialKeyRepeat = 15;

    # Always show scroll bars.
    AppleShowScrollBars = "Always";

    # Use F1–F12 as standard function keys (media via fn+F*).
    "com.apple.keyboard.fnState" = true;

    # Prefer key repeat over press-and-hold character picker.
    ApplePressAndHoldEnabled = false;

    # Disable all automatic text substitution.
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticDashSubstitutionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticQuoteSubstitutionEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
  };

  # Trackpad
  system.defaults.trackpad = {
    # Tap to click.
    Clicking = true;

    # Three-finger drag to select text or move windows by swiping
    # with three fingers (System Settings → Accessibility → Pointer
    # Control → Trackpad Options → Dragging style).
    TrackpadThreeFingerDrag = true;
  };

  # Dock
  system.defaults.dock = {
    autohide = true;
    mru-spaces = false; # don't rearrange Spaces by recent use
    show-recents = false;

    # Magnification on hover.
    magnification = true;
    largesize = 128;

    # Pin only Emacs; remove every other persistent app.
    persistent-apps = ["/Applications/Emacs.app"];

    # Disable all hot corners.
    wvous-tl-corner = 1;
    wvous-tr-corner = 1;
    wvous-bl-corner = 1;
    wvous-br-corner = 1;
  };

  # Automatic timezone
  # Let macOS determine the timezone from the current network location.
  # Requires Location Services in System Settings → Privacy & Security.
  # time.timeZone is left unset (null) so macOS manages it dynamically.

  # Menu bar clock
  system.defaults.menuExtraClock.IsAnalog = true;

  # Battery
  system.defaults.controlcenter.BatteryShowPercentage = true;

  # Finder
  system.defaults.finder = {
    AppleShowAllExtensions = true;
    AppleShowAllFiles = true; # show hidden files
    FXEnableExtensionChangeWarning = false;
    FXDefaultSearchScope = "SCcf"; # search current folder by default
    ShowPathbar = true;
    ShowStatusBar = true;
  };

  # Custom preferences (no first-class nix-darwin option)
  system.defaults.CustomUserPreferences = {
    # Siri / AI
    "com.apple.Siri" = {
      StatusMenuVisible = false;
      UserHasDeclinedEnable = true;
    };
    "com.apple.assistant.support" = {
      "Assistant Enabled" = false;
    };

    # Finder sidebar
    "com.apple.finder" = {
      ShowRecentTags = false;
      SidebarShowingSignedIntoiCloud = false;
      SidebarShowingiCloudDesktop = false;
    };

    # Hide Bonjour computers in Finder sidebar
    "com.apple.NetworkBrowser" = {
      BrowseAllInterfaces = false;
    };

    # Prevent .DS_Store on network and USB volumes
    "com.apple.desktopservices" = {
      DSDontWriteNetworkStores = true;
      DSDontWriteUSBStores = true;
    };
  };

  # Automatic timezone (system-level preference)
  # The toggle lives in /Library/Preferences (needs root). The
  # activation script runs as root during darwin-rebuild switch.
  system.activationScripts.postActivation.text =
    lib.fileContents ../scripts/darwin-post-activation.sh;

  # Security
  # MDM controls FileVault, firewall, and most security policies.
  # We only set preferences that MDM typically leaves open.
  security.pam.services.sudo_local.touchIdAuth = true;

  # Application Layer Firewall (ALF)
  # If MDM already enforces the firewall these are no-ops (MDM wins).
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true; # drop unsolicited ICMP
    allowSignedApp = false;
  };

  # Hostname
  # Do NOT set networking.hostName or networking.computerName.

  # Users
  # The darwin user is declared in flake.nix (users.users.${darwinUser})
  # so Home Manager can derive home.username and home.homeDirectory.

  # Fonts
  # nix-darwin copies these into /Library/Fonts/Nix Fonts/ so that
  # macOS Core Text (and every native app) can discover them.
  fonts.packages = import ../fonts.nix {inherit unstable;};

  # Used by nix-darwin as a safety check. DO NOT change.
  system.stateVersion = 6; # !!! Have you read the comment above?
}
