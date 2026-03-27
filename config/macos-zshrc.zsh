# macOS-specific interactive shell settings.
# Restores features from Apple's stock /etc/zshrc that nix-darwin's
# generated replacement does not include.

# Correctly display UTF-8 with combining characters (e.g. accented chars).
if [[ ! -x /usr/bin/locale ]] || [[ "$(locale LC_CTYPE)" == "UTF-8" ]]; then
    setopt COMBINING_CHARS
fi

# Disable the log builtin so it does not shadow /usr/bin/log.
disable log

# Source Terminal.app (or other terminal program) hooks for CWD tracking,
# resume support, etc.
[[ -r "/etc/zshrc_$TERM_PROGRAM" ]] && . "/etc/zshrc_$TERM_PROGRAM"
