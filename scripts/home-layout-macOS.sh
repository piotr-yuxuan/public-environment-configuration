#!/usr/bin/env zsh
# macOS-specific HOME directory layout additions.
#
# Sourced as a Home Manager activation snippet on every switch.
# $DRY_RUN_CMD is provided by Home Manager.

# On macOS the system video directory is "Movies" (not "Videos").
[[ -e $HOME/mov || -L $HOME/mov ]] || $DRY_RUN_CMD ln -s "$HOME/Movies" "$HOME/mov"

# Hide the default macOS folders from Finder so that only the short
# aliases are visible when browsing $HOME.  The UF_HIDDEN flag tells
# Finder to omit the entry from its directory listing; the folder
# itself continues to work normally for all applications.
for d in Desktop Documents Downloads Movies Music Pictures Public; do
    [[ -d $HOME/$d ]] && $DRY_RUN_CMD chflags hidden "$HOME/$d"
done
