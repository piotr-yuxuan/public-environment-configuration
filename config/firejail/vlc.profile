# VLC: use the shipped firejail profile with NixOS fixups.
#
# private-bin is incompatible with NixOS (Nix store paths are not in
# the locations firejail searches) so it must be disabled.
ignore private-bin

# Portal access for desktop integration (dark/light theme).
dbus-user.talk org.freedesktop.portal.Desktop

include vlc.profile
