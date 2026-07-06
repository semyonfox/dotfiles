#!/usr/bin/env bash
set -euo pipefail

target_power_uw="${GPU_POWER_CAP_UW:-162000000}"
target_voltage_offset="${GPU_VOLTAGE_OFFSET:-20}"
target_pci_id="${GPU_PCI_ID:-1002:73ff}"

log() {
  printf 'apply-gpu-profile: %s\n' "$*" >&2
}

find_gpu() {
  local card vendor device pci_id
  for card in /sys/class/drm/card*/device; do
    [ -e "$card/vendor" ] && [ -e "$card/device" ] || continue
    vendor=$(cat "$card/vendor")
    device=$(cat "$card/device")
    pci_id="${vendor#0x}:${device#0x}"
    if [ "${pci_id,,}" = "${target_pci_id,,}" ]; then
      printf '%s\n' "$card"
      return 0
    fi
  done
  return 1
}

gpu=$(find_gpu || true)
if [ -z "$gpu" ]; then
  log "target GPU $target_pci_id not found; skipping"
  exit 0
fi

hwmon=""
for candidate in "$gpu"/hwmon/hwmon*; do
  [ -e "$candidate/power1_cap" ] || continue
  hwmon="$candidate"
  break
done

for _ in {1..30}; do
  if [ -n "$hwmon" ] && [ -e "$gpu/pp_od_clk_voltage" ] && [ -e "$hwmon/power1_cap" ]; then
    break
  fi
  if [ -z "$hwmon" ]; then
    for candidate in "$gpu"/hwmon/hwmon*; do
      [ -e "$candidate/power1_cap" ] || continue
      hwmon="$candidate"
      break
    done
  fi
  sleep 1
done

if [ ! -e "$gpu/pp_od_clk_voltage" ]; then
  log "pp_od_clk_voltage is unavailable; overdrive is probably not enabled in kernel cmdline"
  exit 0
fi

if [ -z "$hwmon" ] || [ ! -e "$hwmon/power1_cap" ]; then
  log "power1_cap is unavailable; skipping"
  exit 0
fi

if [ -e "$hwmon/power1_cap_max" ]; then
  max_power=$(cat "$hwmon/power1_cap_max")
  if [ "$target_power_uw" -gt "$max_power" ]; then
    log "requested ${target_power_uw}uW exceeds current max ${max_power}uW"
    exit 1
  fi
fi

echo high > "$gpu/power_dpm_force_performance_level"
echo "$target_power_uw" > "$hwmon/power1_cap"
echo "vo $target_voltage_offset" > "$gpu/pp_od_clk_voltage"
echo c > "$gpu/pp_od_clk_voltage"

log "applied power=${target_power_uw}uW dpm=high vo=${target_voltage_offset}"
