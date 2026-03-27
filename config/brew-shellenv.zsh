# Initialise Homebrew into the shell environment.
# At profile time, brew is already on PATH via /etc/paths (Intel) or
# /etc/paths.d/Homebrew (ARM), so we just call it directly.
if command -v brew &>/dev/null; then
    eval "$(brew shellenv)"
fi
