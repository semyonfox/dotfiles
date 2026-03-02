#!/bin/bash

bat=/sys/class/power_supply/BAT0
capacity=$(cat "$bat/capacity" 2>/dev/null) || { echo ""; exit; }
status=$(cat "$bat/status" 2>/dev/null)

if [[ "$status" == "Charging" ]]; then
    icon=$'\uf0e7'   # nf-fa-bolt (charging)
elif [[ $capacity -ge 90 ]]; then
    icon=$'\uf240'   # nf-fa-battery_full
elif [[ $capacity -ge 70 ]]; then
    icon=$'\uf241'   # nf-fa-battery_three_quarters
elif [[ $capacity -ge 50 ]]; then
    icon=$'\uf242'   # nf-fa-battery_half
elif [[ $capacity -ge 30 ]]; then
    icon=$'\uf243'   # nf-fa-battery_quarter
else
    icon=$'\uf244'   # nf-fa-battery_empty
fi

echo "$icon  $capacity%"
