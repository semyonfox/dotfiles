#!/usr/bin/env bash
# battery-profile.sh - waybar custom battery module with power profile tooltip/click

ACTION="${1:-status}"

# cycle power profile: power-saver -> balanced -> performance -> power-saver
if [[ "$ACTION" == "cycle" ]]; then
    current=$(powerprofilesctl get)
    case "$current" in
        power-saver) powerprofilesctl set balanced ;;
        balanced)    powerprofilesctl set performance ;;
        performance) powerprofilesctl set power-saver ;;
        *)           powerprofilesctl set balanced ;;
    esac
    exit 0
fi

# read battery info
BAT_PATH="/sys/class/power_supply/BAT0"
if [[ ! -d "$BAT_PATH" ]]; then
    BAT_PATH=$(find /sys/class/power_supply -name 'BAT*' -maxdepth 1 | head -1)
fi

capacity=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "?")
status=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")

# pick icon based on capacity and charging state (nerd font battery icons)
if [[ "$status" == "Charging" || "$status" == "Full" ]]; then
    icon=$'\uf0e7'   # nf-fa-bolt (charging)
else
    if   (( capacity >= 90 )); then icon=$'\uf240'  # nf-fa-battery_full
    elif (( capacity >= 70 )); then icon=$'\uf241'  # nf-fa-battery_three_quarters
    elif (( capacity >= 50 )); then icon=$'\uf242'  # nf-fa-battery_half
    elif (( capacity >= 20 )); then icon=$'\uf243'  # nf-fa-battery_quarter
    else icon=$'\uf244'                             # nf-fa-battery_empty
    fi
fi

# power profile
profile=$(powerprofilesctl get 2>/dev/null || echo "unknown")
case "$profile" in
    power-saver)  profile_label="Power Saver" ; profile_icon="󰌪" ;;
    balanced)     profile_label="Standard"    ; profile_icon="󰾅" ;;
    performance)  profile_label="Performance" ; profile_icon="󱐋" ;;
    *)            profile_label="Unknown"     ; profile_icon="" ;;
esac

# css class for warning/critical
if [[ "$status" == "Charging" || "$status" == "Full" ]]; then
    css_class="charging"
elif (( capacity <= 15 )); then
    css_class="critical"
elif (( capacity <= 30 )); then
    css_class="warning"
else
    css_class="good"
fi

tooltip="Battery: ${capacity}% (${status})\nPower mode: ${profile_icon} ${profile_label}"

printf '{"text":"%s  %3s%%","tooltip":"%s","class":"%s"}\n' \
    "$icon" "$capacity" "$tooltip" "$css_class"
