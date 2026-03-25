# shellcheck disable=SC2154
# Variables journalctl_cmd, grep_cmd, modprobe_cmd, and sleep_cmd are
# set by the Nix wrapper.

# Watchdog for USB-C monitor hub cycling on the Framework 16 AMD 7040.
#
# The Iiyama PL3494WQ's built-in Realtek hub (0bda:5420) sometimes
# enters a rapid connect/disconnect cycle on USB bus 5-1 due to an
# AMD UCSI firmware race during DP Alt Mode negotiation. When
# detected, this script reloads the UCSI driver and resets the xHCI
# controller to force a clean renegotiation.

XHCI_PCI="0000:c3:00.3"
XHCI_DRIVER="/sys/bus/pci/drivers/xhci_hcd"
THRESHOLD=5
WINDOW=30
COOLDOWN=30
POLL=3

while true; do
    count=$("$journalctl_cmd" -k --since="${WINDOW} seconds ago" \
        --no-pager -q -o cat \
        | "$grep_cmd" -c 'usb 5-1:.*USB disconnect' 2>/dev/null || true)

    if (( count >= THRESHOLD )); then
        echo "Cycling detected (${count} disconnects in ${WINDOW}s), resetting USB-C stack"

        # Reload UCSI to clear the PD/Alt Mode state machine
        "$modprobe_cmd" -r ucsi_acpi 2>/dev/null || true
        "$sleep_cmd" 1

        # Reset the xHCI controller for a clean USB re-enumeration
        echo "${XHCI_PCI}" > "${XHCI_DRIVER}/unbind" 2>/dev/null || true
        "$sleep_cmd" 2
        echo "${XHCI_PCI}" > "${XHCI_DRIVER}/bind" 2>/dev/null || true
        "$sleep_cmd" 1

        # Reload UCSI so Alt Mode renegotiation can proceed
        "$modprobe_cmd" ucsi_acpi 2>/dev/null || true

        echo "Reset complete, cooling down ${COOLDOWN}s"
        "$sleep_cmd" "${COOLDOWN}"
    fi

    "$sleep_cmd" "${POLL}"
done
