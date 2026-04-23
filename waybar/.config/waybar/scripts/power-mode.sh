#!/usr/bin/env bash
# waybar custom module: shows current power-mode icon, click cycles
# reads cache written by ~/.local/bin/power-mode.sh

mode=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/power-mode" 2>/dev/null || echo ac)
bat=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")

case "$mode" in
    beast)  text=󰓅 cls=beast  name=Beast  ;;
    ac)     text=󰚥 cls=ac     name=AC     ;;
    mobile) text=󰂄 cls=mobile name=Mobile ;;
    saver)  text=󰌪 cls=saver  name=Saver  ;;
    *)      text=󰂑 cls=unknown name=$mode ;;
esac

printf '{"text":"%s","tooltip":"%s · %s%%","class":"%s","alt":"%s"}\n' \
    "$text" "$name" "$bat" "$cls" "$mode"
