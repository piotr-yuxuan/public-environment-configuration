# shellcheck disable=SC2154
# Variables firejail, firefox, profile_path are set by the Nix wrapper.

# If a sandboxed Firefox session is already running, join it
# (avoids creating spurious empty timestamped directories when
# the user clicks a link in another application).
if "$firejail" --list 2>/dev/null | grep -q ":firefox-dev:"; then
  exec "$firejail" --join=firefox-dev -- "$firefox" "$@"
fi

# First launch: create a per-session timestamped download directory.
download_dir="$HOME/Downloads/firefox-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$download_dir"

exec "$firejail" \
  --name=firefox-dev \
  --profile="$profile_path" \
  --whitelist="$download_dir" \
  "$firefox" "$@"
