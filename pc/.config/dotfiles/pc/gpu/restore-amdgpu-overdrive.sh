#!/usr/bin/env bash
set -euo pipefail

limine_default="/etc/default/limine"
featuremask="amdgpu.ppfeaturemask=0xffffffff"

if (( EUID != 0 )); then
  echo "Run as root: sudo $0" >&2
  exit 1
fi

if grep -q "$featuremask" "$limine_default"; then
  echo "$featuremask already present in $limine_default"
else
  cp -a "$limine_default" "$limine_default.bak.$(date +%Y%m%d-%H%M%S)"
  if ! grep -q 'KERNEL_CMDLINE\[default\]+=' "$limine_default"; then
    echo "Could not find KERNEL_CMDLINE[default]+= in $limine_default" >&2
    exit 1
  fi
  sed -i "s/KERNEL_CMDLINE\\[default\\]+=\"/KERNEL_CMDLINE[default]+=\"$featuremask /" "$limine_default"
  echo "Added $featuremask to $limine_default"
fi

limine-mkinitcpio

install -Dm755 "$(dirname "$0")/apply-gpu-profile.sh" /usr/local/sbin/apply-gpu-profile
install -Dm644 "$(dirname "$0")/gpu-performance-oc.service" /etc/systemd/system/gpu-performance-oc.service
systemctl daemon-reload
systemctl enable gpu-performance-oc.service

echo
echo "Reboot, then verify:"
echo "  cat /proc/cmdline | grep -o '$featuremask'"
echo "  test -e /sys/class/drm/card1/device/pp_od_clk_voltage"
echo "  systemctl restart gpu-performance-oc.service"
echo "  cat /sys/class/drm/card1/device/hwmon/hwmon*/power1_cap"
echo
echo "If the GPU profile is unstable after reboot:"
echo "  1. Select another kernel/snapshot in Limine, or edit the entry and remove '$featuremask'."
echo "  2. Once booted, remove '$featuremask' from $limine_default."
echo "  3. Run: sudo limine-mkinitcpio"
echo "  4. Optionally disable the profile: sudo systemctl disable gpu-performance-oc.service"
