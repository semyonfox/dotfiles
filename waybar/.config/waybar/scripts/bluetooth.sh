#!/usr/bin/env bash
# bluetooth.sh - waybar custom bluetooth module

# nerd font MD icons (supplementary plane, nf-md-bluetooth_*)
icon_off=$'\U000F00B2'        # 󰂲 bluetooth_off
icon_on=$'\U000F00AF'         # 󰂯 bluetooth (on, no device)
icon_connected=$'\U000F00B1'  # 󰂱 bluetooth_connect

powered=$(bluetoothctl show | awk '/Powered:/{print $2}')

if [[ "$powered" != "yes" ]]; then
    printf '{"text":"%s","tooltip":"Bluetooth off","class":"off"}\n' "$icon_off"
    exit 0
fi

# get connected devices
mapfile -t devices < <(bluetoothctl devices Connected 2>/dev/null | awk '{$1=$2=""; print substr($0,3)}')

if [[ ${#devices[@]} -eq 0 ]]; then
    printf '{"text":"%s","tooltip":"No devices connected","class":"on"}\n' "$icon_on"
    exit 0
fi

# build tooltip listing all connected device names
tooltip=$(printf '%s\n' "${devices[@]}" | paste -sd '\n')

# show first device name in bar if only one, else count
if [[ ${#devices[@]} -eq 1 ]]; then
    label="${devices[0]}"
else
    label="${#devices[@]} devices"
fi

printf '{"text":"%s  %s","tooltip":"%s","class":"connected"}\n' \
    "$icon_connected" "$label" "$tooltip"
