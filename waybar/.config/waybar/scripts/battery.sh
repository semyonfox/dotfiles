#!/usr/bin/env bash
# waybar custom/battery: icon = current power mode, percent rescaled against
# the firmware charge cap. click cycles via ~/.local/bin/power-mode.sh.

read_sysfs() { cat "$1" 2>/dev/null || echo "$2"; }

mode=$(read_sysfs "${XDG_CACHE_HOME:-$HOME/.cache}/power-mode" ac)
raw=$(read_sysfs /sys/class/power_supply/BAT0/capacity 0)
state=$(read_sysfs /sys/class/power_supply/BAT0/status Unknown)
cap=$(read_sysfs /sys/class/power_supply/BAT0/charge_control_end_threshold 100)

if [ "$cap" -gt 0 ] && [ "$cap" -lt 100 ]; then
    pct=$(( raw * 100 / cap ))
    [ "$pct" -gt 100 ] && pct=100
    detail="${pct}% (${raw}% raw, cap ${cap}%)"
else
    pct=$raw
    detail="${pct}%"
fi

case "$mode" in
    beast)  icon=󰓅 name=Beast  ;;
    ac)     icon=󰚥 name=AC     ;;
    mobile) icon=󰂄 name=Mobile ;;
    saver)  icon=󰌪 name=Saver  ;;
    *)      icon=󰂑 name=$mode  ;;
esac

state_lc=$(echo "$state" | tr '[:upper:]' '[:lower:]')

printf '{"text":"%s %s%%","tooltip":"%s · %s · %s","class":"%s","alt":"%s"}\n' \
    "$icon" "$pct" "$name" "$detail" "$state_lc" "$mode" "$mode"
