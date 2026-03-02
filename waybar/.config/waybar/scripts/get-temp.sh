#!/bin/bash

# Auto-detect CPU temperature from available sensors
# Falls back gracefully if no sensors found

# Try multiple common hwmon paths
TEMP_PATH=""

for hwmon in /sys/class/hwmon/hwmon*/; do
  if [ -f "${hwmon}temp1_input" ]; then
    TEMP_PATH="${hwmon}temp1_input"
    break
  fi
done

# Fallback: try acpitz or other sources
if [ -z "$TEMP_PATH" ]; then
  for zone in /sys/class/thermal/thermal_zone*/; do
    if [ -f "${zone}type" ]; then
      zone_type=$(cat "${zone}type")
      if [[ "$zone_type" =~ (x86_pkg_temp|coretemp|acpitz) ]]; then
        TEMP_PATH="${zone}temp"
        break
      fi
    fi
  done
fi

# Get temperature or return fallback
if [ -f "$TEMP_PATH" ]; then
  TEMP_C=$(cat "$TEMP_PATH" | awk '{print int($1/1000)}')
  echo "$TEMP_C"
else
  echo "N/A"
fi
