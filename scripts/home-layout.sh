#!/usr/bin/env zsh
# Cross-platform HOME directory layout.
#
# Creates short-named aliases (symlinks) pointing at the standard user
# directories, and plain working directories for source code, binaries,
# and documentation, as declared in readme.org §Organisation of $HOME.
#
# Sourced as a Home Manager activation snippet on every switch.
# $DRY_RUN_CMD is provided by Home Manager (empty in normal mode,
# "echo" in --dry-run mode).

# Plain working directories
[[ -d $HOME/bin ]] || $DRY_RUN_CMD mkdir -p "$HOME/bin"
[[ -d $HOME/man ]] || $DRY_RUN_CMD mkdir -p "$HOME/man"
[[ -d $HOME/pkg ]] || $DRY_RUN_CMD mkdir -p "$HOME/pkg"
# ~/src may be redirected to a Dropbox-backed path by a platform-specific
# activation script.  Only create the github.com placeholder when ~/src
# is a plain directory (not already a symlink established by that script).
[[ -d $HOME/src || -L $HOME/src ]] || $DRY_RUN_CMD mkdir -p "$HOME/src"
if [[ -d $HOME/src && ! -L $HOME/src ]]; then
    [[ -d $HOME/src/github.com ]] || $DRY_RUN_CMD mkdir -p "$HOME/src/github.com"
fi

# Screenshots directory under the Pictures alias
[[ -d $HOME/Pictures ]] || $DRY_RUN_CMD mkdir -p "$HOME/Pictures"
[[ -d $HOME/Pictures/screenshots ]] || $DRY_RUN_CMD mkdir -p "$HOME/Pictures/screenshots"

# Symlinks to standard user directories.
# Each guard checks for both a real path (-e) and a dangling symlink
# (-L) so an already-existing link is never blindly overwritten.
[[ -e $HOME/img || -L $HOME/img ]] || $DRY_RUN_CMD ln -s "$HOME/Pictures" "$HOME/img"
[[ -e $HOME/net || -L $HOME/net ]] || $DRY_RUN_CMD ln -s "$HOME/Downloads" "$HOME/net"
[[ -e $HOME/pvt || -L $HOME/pvt ]] || $DRY_RUN_CMD ln -s "$HOME/Documents" "$HOME/pvt"
[[ -e $HOME/snd || -L $HOME/snd ]] || $DRY_RUN_CMD ln -s "$HOME/Music" "$HOME/snd"
# dist points at the Maven local repository; it may be a dangling
# symlink until the first Maven or Leiningen build populates .m2/.
[[ -e $HOME/dist || -L $HOME/dist ]] || $DRY_RUN_CMD ln -s "$HOME/.m2/repository" "$HOME/dist"
