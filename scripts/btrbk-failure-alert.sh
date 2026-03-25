# shellcheck disable=SC2154
# Variables stat_cmd, id_cmd, notify_send, and emacsclient are set by the
# Nix wrapper.

msg="SNAPSHOT FAILURE: btrbk-home.service failed. Run: journalctl -u btrbk-home.service"

# Write to all PTYs owned by caocoa.
# wall(1) uses utmp to find targets, but GUI terminal emulators
# (GNOME Console, Emacs eat, VS Code) do not register utmp entries,
# so wall never reaches them.  Writing directly to each user-owned
# PTY bypasses that limitation.
# Note: mistty redraws its buffer and swallows injected PTY output,
# so it is covered by the emacsclient warning below instead.
for pts in /dev/pts/[0-9]*; do
  [ -c "$pts" ] || continue
  owner=$("$stat_cmd" -c %U "$pts" 2>/dev/null) || continue
  [ "$owner" = "caocoa" ] || continue
  printf '\n\033[1;31m*** %s ***\033[0m\n' "$msg" > "$pts" 2>/dev/null || true
done

uid=$("$id_cmd" -u caocoa)

# Emacs warning buffer (covers mistty and any Emacs frame).
/run/wrappers/bin/sudo -u caocoa "$emacsclient" -e \
  "(display-warning 'btrbk \"$msg\" :error)" \
  2>/dev/null || true

# Desktop notification via D-Bus.
if [ -d "/run/user/$uid" ]; then
  /run/wrappers/bin/sudo -u caocoa \
    DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
    "$notify_send" -u critical \
    "Snapshot FAILED" \
    "btrbk-home.service failed. Run: journalctl -u btrbk-home.service"
fi
