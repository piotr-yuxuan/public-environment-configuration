# Home Manager — work Mac overrides (nix-darwin, aarch64-darwin).
#
# Imported alongside home/base.nix for the work user.
# `unstable` is available via extraSpecialArgs.
{ pkgs, lib, ... }:

{
  # ════════════════════════════════════════════════════════════════════
  #  Work-only packages
  # ════════════════════════════════════════════════════════════════════

  home.packages = [
    # ── Languages & runtimes (work-specific) ───────────────────────
    pkgs.luarocks
    pkgs.pipenv
    pkgs.poetry

    # ── Language servers (work-specific) ───────────────────────────
    # texlab moved to home/base.nix (cross-platform)

    # ── VCS / GitOps ───────────────────────────────────────────────
    pkgs.glab
    pkgs.gitlab-runner

    # ── Text / docs ────────────────────────────────────────────────
    pkgs.gnugrep
    pkgs.gnused
  ];

  # ════════════════════════════════════════════════════════════════════
  #  Git identity (work — fill in before first use)
  # ════════════════════════════════════════════════════════════════════

  programs.git.settings.user = {
    # TODO: Replace with your real work name and email.
    name  = lib.mkForce "example";
    email = lib.mkForce "example@example.com";
  };

  # ════════════════════════════════════════════════════════════════════
  #  macOS environment
  # ════════════════════════════════════════════════════════════════════

  home.sessionVariables = {
    # Homebrew security hardening.
    HOMEBREW_CASK_OPTS            = "--require-sha";
    HOMEBREW_FORCE_BREWED_CURL    = "1";
    HOMEBREW_NO_ANALYTICS         = "1";
    HOMEBREW_NO_GITHUB_API        = "1";
    HOMEBREW_NO_INSECURE_REDIRECT = "1";

    ARCHFLAGS = "-arch ${
      if pkgs.stdenv.hostPlatform.isAarch64 then "arm64" else "x86_64"
    }";
  };

  # Homebrew binary paths — prepended to PATH so brew-managed tools that
  # have not yet been migrated to nix are found.
  home.sessionPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/curl/bin"
  ];

  # ════════════════════════════════════════════════════════════════════
  #  Brewfile integration (imperative bridging for macOS GUI apps)
  # ════════════════════════════════════════════════════════════════════

  home.activation.brewBundle =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      BREWFILE="${../config/Brewfile}"
      ${lib.fileContents ../scripts/brew-bundle-activation.sh}
    '';

  # ════════════════════════════════════════════════════════════════════
  #  Clear .hushlogin at login so the shell greeting runs once per session
  # ════════════════════════════════════════════════════════════════════

  launchd.agents.clear-hushlogin = {
    enable = true;
    config = {
      Label             = "com.user.clear-hushlogin";
      ProgramArguments  = [ "/bin/sh" "-c" "/bin/rm -f \"$HOME/.hushlogin\"" ];
      RunAtLoad         = true;
      StandardErrorPath = "/dev/null";
      StandardOutPath   = "/dev/null";
    };
  };
}
