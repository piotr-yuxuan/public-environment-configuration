#!/usr/bin/env bash
# macOS-specific HOME directory layout additions.
#
# Sourced as a Home Manager activation snippet on every switch.
# $DRY_RUN_CMD is provided by Home Manager.
# $CHFLAGS_BIN may be overridden in tests to point at a mock binary;
# it defaults to the absolute path so the script works even when /usr/bin
# is absent from the activation environment's PATH.
chflags_bin=${CHFLAGS_BIN:-/usr/bin/chflags}

# On macOS the system video directory is "Movies" (not "Videos").
[[ -e $HOME/mov || -L $HOME/mov ]] || $DRY_RUN_CMD ln -s "$HOME/Movies" "$HOME/mov"

# Hide the default macOS folders from Finder so that only the short
# aliases are visible when browsing $HOME.  The UF_HIDDEN flag tells
# Finder to omit the entry from its directory listing; the folder
# itself continues to work normally for all applications.
for d in Desktop Documents Downloads Movies Music Pictures Public; do
    if [[ -d $HOME/$d ]]; then
        $DRY_RUN_CMD $chflags_bin hidden "$HOME/$d"
    fi
done
