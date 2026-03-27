# Home Manager macOS overrides (nix-darwin).
#
# Imported alongside home/base.nix for the macOS user.
# `unstable` is available via extraSpecialArgs.
{
  pkgs,
  lib,
  ...
}: {
  #  macOS only packages

  home.packages = [
    # Languages & runtimes (macOS specific)
    pkgs.luarocks
    pkgs.pipenv
    pkgs.poetry

    # Language servers (macOS specific)
    # texlab moved to home/base.nix (cross-platform)

    # VCS / GitOps
    pkgs.glab
    pkgs.gitlab-runner

    # Text / docs
    pkgs.gnugrep
    pkgs.gnused
  ];

  #  Git identity (fill in before first use)

  programs.git.settings.user = {
    # TODO: Replace with your real name and email.
    name = lib.mkForce "example";
    email = lib.mkForce "example@example.com";
  };

  #  macOS environment

  home.sessionVariables = {
    # Homebrew security hardening.
    HOMEBREW_CASK_OPTS = "--require-sha";
    HOMEBREW_FORCE_BREWED_CURL = "1";
    HOMEBREW_NO_ANALYTICS = "1";
    HOMEBREW_NO_GITHUB_API = "1";
    HOMEBREW_NO_INSECURE_REDIRECT = "1";
    HOMEBREW_NO_ENV_HINTS = "1";

    ARCHFLAGS = "-arch ${
      if pkgs.stdenv.hostPlatform.isAarch64
      then "arm64"
      else "x86_64"
    }";
  };

  # Bootstrap Homebrew: probes the arm64 and Intel prefixes at shell startup
  # so PATH, MANPATH, and INFOPATH are set correctly on either architecture.
  programs.zsh.profileExtra = lib.fileContents ../config/brew-shellenv.zsh;

  # Restore macOS-specific interactive shell features (COMBINING_CHARS,
  # disable log builtin, Terminal.app hooks) that nix-darwin's generated
  # /etc/zshrc omits.
  programs.zsh.initContent = lib.fileContents ../config/macos-zshrc.zsh;

  #  Brewfile integration (imperative bridging for macOS GUI apps)

  home.activation.brewBundle = lib.hm.dag.entryAfter ["writeBoundary"] ''
    BREWFILE="${../config/Brewfile}"
    ${lib.fileContents ../scripts/brew-bundle-activation.sh}
  '';

  #  macOS desktop wallpaper

  home.activation.setWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    WALLPAPER="${../img/wallpaper.jpg}"
    ${lib.fileContents ../scripts/macos-set-wallpaper.sh}
  '';

  #  Clear .hushlogin at login so the shell greeting runs once per session

  launchd.agents.clear-hushlogin = {
    enable = true;
    config = {
      Label = "com.user.clear-hushlogin";
      ProgramArguments = ["/bin/sh" "-c" "/bin/rm -f \"$HOME/.hushlogin\""];
      RunAtLoad = true;
      StandardErrorPath = "/dev/null";
      StandardOutPath = "/dev/null";
    };
  };

  #  Nix flake staleness check (weekly)
  #
  # Warns via terminal notification if any flake input is older than
  # 14 days.  Runs weekly on Monday at 09:00; launchd catches up after
  # sleep or shutdown automatically.

  launchd.agents.nix-staleness-check = {
    enable = true;
    config = {
      Label = "com.user.nix-staleness-check";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        (lib.fileContents ../scripts/nix-staleness-check.sh)
      ];
      StartCalendarInterval = [
        {
          Weekday = 1;
          Hour = 9;
          Minute = 0;
        }
      ];
      StandardErrorPath = "/dev/null";
      StandardOutPath = "/dev/null";
    };
  };
}
