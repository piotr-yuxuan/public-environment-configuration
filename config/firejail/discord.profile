# Discord: sandboxed with portal access for desktop
# integration (dark/light theme, screen sharing).
dbus-user.talk org.freedesktop.portal.Desktop

# NixOS fix: the upstream profile restricts to a static
# /usr/bin path that does not exist on NixOS.
ignore private-bin

include discord.profile
