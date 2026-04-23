#!/bin/bash

# Auto-detect CPU temperature from available sensors
# Averages all CPU cores for accurate reading

HWMON_PATH=""
for hwmon in /sys/class/hwmon/hwmon*/; do
  name=$(cat "${hwmon}name" 2>/dev/null)
  if [[ "$name" == "coretemp" ]]; then
    HWMON_PATH="$hwmon"
    break
  fi
done

if [ -z "$HWMON_PATH" ]; then
  for zone in /sys/class/thermal/thermal_zone*/; do
    if [ -f "${zone}type" ]; then
      zone_type=$(cat "${zone}type")
      if [[ "$zone_type" =~ (x86_pkg_temp|coretemp|acpitz) ]]; then
        TEMP_C=$(cat "${zone}temp" | awk '{print int($1/1000)}')
        echo "$TEMP_C"
        exit 0
      fi
    fi
  done
  echo "N/A"
  exit 0
fi

temps=()
for temp_file in "${HWMON_PATH}"temp*_input; do
  label_file="${temp_file%_input}_label"
  if [ -f "$label_file" ]; then
    label=$(cat "$label_file")
    if [[ "$label" =~ ^Core ]]; then
      temp=$(cat "$temp_file" | awk '{print int($1/1000)}')
      temps+=("$temp")
    fi
  fi
done

if [ ${#temps[@]} -eq 0 ]; then
  echo "N/A"
else
  sum=0
  for t in "${temps[@]}"; do
    sum=$((sum + t))
  done
  avg=$((sum / ${#temps[@]}))
  echo "$avg"
fi
