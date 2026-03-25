# macos-set-wallpaper.sh — sourced as a Home Manager activation script.
# WALLPAPER is set by Nix interpolation in work.nix before this script runs.

$DRY_RUN_CMD /usr/bin/osascript -e \
  'tell application "System Events" to tell every desktop to set picture to "'"$WALLPAPER"'"'
