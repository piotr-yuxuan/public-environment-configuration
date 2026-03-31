#!/usr/bin/env bash
# Sets Finder sidebar favourite locations.
#
# Sourced as a Home Manager activation snippet on every switch.
# MYSIDES_BIN must be set by the caller (home/macOS.nix activation snippet).
# $DRY_RUN_CMD is provided by Home Manager.

if [[ ! -x "$MYSIDES_BIN" ]]; then
    echo "finder-favorites: mysides not yet installed; skipping" >&2
else

    # Remove any sidebar entry that is not in our managed set.
    # Reading from mysides list directly (read-only; no $DRY_RUN_CMD needed).
    # Output format: "name -> file:///path"
    while read -r line; do
        name="${line%% -> *}"
        $DRY_RUN_CMD "$MYSIDES_BIN" remove "$name" 2>/dev/null
    done < <("$MYSIDES_BIN" list 2>/dev/null)

    wanted=(Applications Home img mov net pvt snd src)
    for name in "${wanted[@]}"; do
        $DRY_RUN_CMD "$MYSIDES_BIN" add "$name" "file://$HOME/$name/"
    done
fi
