#!/bin/bash
# Waybar Bluetooth module script
# Shows device name if only one connected, count if multiple

get_bluetooth_status() {
    if ! bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
        printf '{"text": "", "alt": "off", "tooltip": "Bluetooth: Off", "class": "off"}\n'
        return
    fi

    # Get connected devices count
    local count=$(bluetoothctl devices Connected 2>/dev/null | wc -l)

    if [ "$count" -le 0 ]; then
        printf '{"text": "", "alt": "on", "tooltip": "Bluetooth: On (no devices)", "class": "on"}\n'
    elif [ "$count" -eq 1 ]; then
        # Single device - get its alias using dbus if possible
        local device_mac=$(bluetoothctl devices Connected 2>/dev/null | grep -o '[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]' | head -1)
        local device_name=$(bluetoothctl info "$device_mac" 2>/dev/null | grep "Alias:" | awk -F': ' '{print $2}')
        local tooltip="Bluetooth: $device_name"
        printf '{"text": "  %s", "alt": "on", "tooltip": "%s", "class": "connected"}\n' "$device_name" "$tooltip"
    else
        # Multiple devices - show count
        printf '{"text": "  %d", "alt": "on", "tooltip": "Bluetooth: %d devices", "class": "connected"}\n' "$count" "$count"
    fi
}

get_bluetooth_status
