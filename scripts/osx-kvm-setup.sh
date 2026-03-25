#!/usr/bin/env bash
# OSX-KVM initial setup: clone repo, fetch macOS installer, create virtual disk.
#
# Prerequisites (provided by NixOS config):
#   - QEMU, libvirtd, virt-manager (system level)
#   - dmg2img, p7zip, cdrtools, tesseract (user level)
#   - User in kvm, libvirtd, input groups
#   - KVM modprobe options (ignore_msrs, nested) loaded
#
# Usage:
#   ./scripts/osx-kvm-setup.sh [disk_size]
#   disk_size defaults to 256G.

set -euo pipefail

DISK_SIZE="${1:-256G}"
OSX_KVM_DIR="$HOME/OSX-KVM"

echo "==> Verifying KVM access..."
if [[ ! -r /dev/kvm ]]; then
  echo "ERROR: /dev/kvm is not accessible. Ensure you have rebuilt NixOS"
  echo "       and re-logged in so group membership takes effect."
  exit 1
fi

echo "==> Cloning OSX-KVM repository..."
if [[ -d "$OSX_KVM_DIR" ]]; then
  echo "    $OSX_KVM_DIR already exists; pulling latest changes."
  git -C "$OSX_KVM_DIR" pull --rebase
else
  git clone --depth 1 --recursive https://github.com/kholia/OSX-KVM.git "$OSX_KVM_DIR"
fi

cd "$OSX_KVM_DIR"

echo "==> Fetching macOS installer..."
echo "    (Choose a version when prompted)"
python3 fetch-macOS-v2.py

echo "==> Converting BaseSystem.dmg to BaseSystem.img..."
dmg2img -i BaseSystem.dmg BaseSystem.img

if [[ ! -f mac_hdd_ng.img ]]; then
  echo "==> Creating virtual disk (${DISK_SIZE})..."
  qemu-img create -f qcow2 mac_hdd_ng.img "$DISK_SIZE"
else
  echo "==> Virtual disk mac_hdd_ng.img already exists; skipping creation."
fi

echo ""
echo "Setup complete. To start the macOS installer, run:"
echo "  cd ~/OSX-KVM && ./OpenCore-Boot.sh"
echo ""
echo "Inside the installer:"
echo "  1. Open Disk Utility and format the virtual disk as APFS."
echo "  2. Proceed with macOS installation."
echo "  3. Be patient at the Country Selection screen (Big Sur+)."
