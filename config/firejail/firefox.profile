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

# Portal access for desktop integration under Wayland.  The upstream
# profile only allows org.freedesktop.portal.Documents.  Without this
# Firefox cannot read the system color-scheme (dark/light) from
# org.freedesktop.portal.Settings and screen sharing is broken.
dbus-user.talk org.freedesktop.portal.Desktop

include firefox-developer-edition.profile
