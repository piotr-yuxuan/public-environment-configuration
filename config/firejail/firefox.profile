# Firefox Developer Edition: sandboxed with ~/Downloads access.
#
# private-bin is incompatible with NixOS (Nix store paths are not in
# the locations firejail searches) so it must be disabled.
ignore private-bin
ignore whitelist ${DOWNLOADS}
whitelist ${HOME}/Downloads

# NixOS Firefox uses XDG paths (~/.config/mozilla, ~/.cache/mozilla)
# rather than ~/.mozilla.  Whitelist them so profiles, logins, and
# cache persist across sessions.
noblacklist ${HOME}/.config/mozilla
noblacklist ${HOME}/.cache/mozilla
whitelist ${HOME}/.config/mozilla
whitelist ${HOME}/.cache/mozilla
include firefox-developer-edition.profile
