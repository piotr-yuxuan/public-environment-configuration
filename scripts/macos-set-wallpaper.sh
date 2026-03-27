#!/usr/bin/env zsh

# Sourced as a Home Manager activation script.

UID_OF_USER=$(/usr/bin/id -u "$USER")
$DRY_RUN_CMD /bin/launchctl asuser "$UID_OF_USER" \
    /usr/bin/osascript -e \
    'tell application "System Events" to tell every desktop to set picture to "'"$WALLPAPER"'"'
