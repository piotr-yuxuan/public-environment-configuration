#!/bin/sh
# Post-activation hardening for the work (macOS) machine.
# Called by nix-darwin's system.activationScripts.postActivation.
# Runs as root during darwin-rebuild switch.

# Automatic timezone
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool true

# Network hardening: reject ICMP redirects on untrusted Wi-Fi.
# macOS default is 1 (accept); set to 0 (drop).
/usr/sbin/sysctl -w net.inet.icmp.drop_redirect=1 >/dev/null 2>&1 || true

# Gatekeeper: verify assessments are enabled.
if ! /usr/sbin/spctl --status 2>/dev/null | /usr/bin/grep -q 'assessments enabled'; then
  echo "WARNING: Gatekeeper is not enabled. Run: sudo spctl --master-enable" >&2
fi
