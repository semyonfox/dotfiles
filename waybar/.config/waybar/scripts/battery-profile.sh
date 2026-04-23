#!/usr/bin/env bash
# battery-profile.sh - waybar custom battery module with power profile actions

ACTION="${1:-status}"

current_profile() {
    powerprofilesctl get 2>/dev/null || echo "unknown"
}

set_profile() {
    local target="$1"
    powerprofilesctl set "$target" >/dev/null 2>&1 || true
}

case "$ACTION" in
    cycle)
        # power-saver -> balanced -> performance -> power-saver
        current="$(current_profile)"
        case "$current" in
            power-saver) set_profile balanced ;;
            balanced)    set_profile performance ;;
            performance) set_profile power-saver ;;
            *)           set_profile balanced ;;
        esac
        exit 0
        ;;
    toggle)
        # balanced <-> performance
        current="$(current_profile)"
        case "$current" in
            performance) set_profile balanced ;;
            *)           set_profile performance ;;
        esac
        exit 0
        ;;
    set)
        # set <power-saver|balanced|performance>
        if [[ -n "${2:-}" ]]; then
            set_profile "$2"
        fi
        exit 0
        ;;
esac

# read battery info
BAT_PATH=""
for candidate in /sys/class/power_supply/BAT*; do
    if [[ -d "$candidate" ]]; then
        BAT_PATH="$candidate"
        break
    fi
done

if [[ -z "$BAT_PATH" ]]; then
    printf '{"text":" AC","tooltip":"No battery detected","class":"good"}\n'
    exit 0
fi

capacity=$(cat "$BAT_PATH/capacity" 2>/dev/null || echo "?")
status=$(cat "$BAT_PATH/status" 2>/dev/null || echo "Unknown")

# pick icon based on capacity and charging state (nerd font battery icons)
if [[ "$status" == "Charging" ]]; then
    icon=$'\uf0e7'   # nf-fa-bolt
elif [[ "$status" == "Full" ]]; then
    icon=$'\uf240'   # nf-fa-battery_full
else
    if   (( capacity >= 90 )); then icon=$'\uf240'  # nf-fa-battery_full
    elif (( capacity >= 70 )); then icon=$'\uf241'  # nf-fa-battery_three_quarters
    elif (( capacity >= 50 )); then icon=$'\uf242'  # nf-fa-battery_half
    elif (( capacity >= 20 )); then icon=$'\uf243'  # nf-fa-battery_quarter
    else icon=$'\uf244'                             # nf-fa-battery_empty
    fi
fi

# power profile
profile="$(current_profile)"
case "$profile" in
    power-saver)  profile_label="Power Saver" ; profile_icon="" ;;
    balanced)     profile_label="Balanced"    ; profile_icon="" ;;
    performance)  profile_label="Performance" ; profile_icon="" ;;
    *)            profile_label="Unknown"     ; profile_icon="" ;;
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

printf '{"text":"%s %s%%","tooltip":"%s","class":"%s"}\n' \
    "$icon" "$capacity" "$tooltip" "$css_class"
