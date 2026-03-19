# brew-bundle-activation.sh — sourced as a home-manager activation script.
# Runs on every `home-manager switch` on macOS.
# BREWFILE is set by Nix interpolation in work.nix before this script runs.

# Refresh the Homebrew formula/cask index before installing.
# Equivalent to `apt update`; keeps formula metadata and available versions current.
$DRY_RUN_CMD brew update

# Install or upgrade all Brewfile entries.
# --upgrade: bring already-installed packages up to the latest formula version.
$DRY_RUN_CMD brew bundle install --file "$BREWFILE" --upgrade
# Uncomment to also remove Homebrew packages not listed in the Brewfile:
# $DRY_RUN_CMD brew bundle cleanup --file "$BREWFILE" --force
