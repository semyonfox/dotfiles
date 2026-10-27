#!/usr/bin/env bash
# the portable apt panel forgets its ddc settings whenever it loses power and
# boots at brightness 22 and contrast 0, so hyprland reruns this on every hotplug
set -e

model="AIBPMTR-0225"

# skip the ddc retries unless the panel is actually connected
grep -qa "$model" /sys/class/drm/*/edid 2>/dev/null || exit 0

# ddc/ci takes a few seconds to answer after hotplug, and noctalia polls the same bus
for _ in 1 2 3 4 5 6 7 8; do
    if ddcutil --mfg APT --model "$model" setvcp 10 100 12 100 >/dev/null 2>&1; then
        exit 0
    fi
    sleep 2
done
echo "ddc-defaults: $model did not accept ddc writes" >&2
exit 1
