#!/usr/bin/env zsh

# Sourced as a home-manager activation script. Runs on every
# `home-manager switch` on macOS. BREWFILE is set by Nix interpolation
# in macOS.nix before this script runs.

# Locate Homebrew at the well-known prefixes (ARM then Intel). During
# activation the PATH is minimal, so we cannot rely on `command -v
# brew`.
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
else
    echo "brewBundle: skipping Brewfile activation because Homebrew is not found." >&2
    return -1 2>/dev/null || exit -1
fi

# Refresh the Homebrew formula/cask index before installing.
# Equivalent to `apt update`; keeps formula metadata and available
# versions current.
$DRY_RUN_CMD brew update

# Install or upgrade all Brewfile entries.
# --upgrade: bring already-installed packages up to the latest formula version.
$DRY_RUN_CMD brew bundle install --file "$BREWFILE" --upgrade
# Fail unless the Brewfile is on par with what is currently installed,
# but don't silently uninstall anything without user control.
$DRY_RUN_CMD brew bundle cleanup --file "$BREWFILE"
