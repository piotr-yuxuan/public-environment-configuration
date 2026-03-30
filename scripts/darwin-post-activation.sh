#!/bin/sh
# Post-activation hardening for macOS machines.
# Called by nix-darwin's system.activationScripts.postActivation.
# Runs as root during darwin-rebuild switch.

# Automatic timezone
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true

# Login screen: show the keyboard input menu so the layout tracks the last
# logged-in user rather than the system default.
/usr/bin/defaults write /Library/Preferences/com.apple.loginwindow ShowInputMenu -bool true

# Network hardening: reject ICMP redirects on untrusted Wi-Fi.
# macOS default is 1 (accept); set to 0 (drop).
/usr/sbin/sysctl -w net.inet.icmp.drop_redirect=1 >/dev/null 2>&1 || true

# Gatekeeper: verify assessments are enabled.
if ! /usr/sbin/spctl --status 2>/dev/null | /usr/bin/grep -q 'assessments enabled'; then
  echo "WARNING: Gatekeeper is not enabled. Run: sudo spctl --master-enable" >&2
fi

# FileVault (full-disk encryption): warn if not active.
FV_STATUS=$(/usr/bin/fdesetup status 2>/dev/null || true)
if echo "$FV_STATUS" | /usr/bin/grep -q 'FileVault is Off'; then
  echo "WARNING: FileVault is OFF. Enable it: System Settings → Privacy & Security → FileVault." >&2
fi

# SIP (System Integrity Protection): warn if disabled.
SIP_STATUS=$(/usr/bin/csrutil status 2>/dev/null || true)
if echo "$SIP_STATUS" | /usr/bin/grep -q 'disabled'; then
  echo "WARNING: System Integrity Protection is disabled." >&2
fi

# Disable remote login (SSH) unless explicitly wanted.
/usr/sbin/systemsetup -setremotelogin off 2>/dev/null || true

# Disable wake-on-LAN (prevents powering on from remote).
/usr/bin/pmset -a womp 0 2>/dev/null || true

# Disable IR receiver (if present).
/usr/bin/defaults write /Library/Preferences/com.apple.driver.AppleIRController DeviceEnabled -bool false 2>/dev/null || true
