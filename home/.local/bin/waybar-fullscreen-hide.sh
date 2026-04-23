#!/usr/bin/env bash
# hide waybar when any window enters fullscreen, show again on exit.
# subscribes to hyprland's IPC event socket; toggles via SIGUSR1.
set -euo pipefail

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
[ -S "$sock" ] || { echo "no hyprland event socket at $sock" >&2; exit 0; }

hidden=0
nc -U "$sock" | while IFS= read -r line; do
    case "$line" in
        fullscreen\>\>1)
            [ "$hidden" -eq 0 ] && pkill -SIGUSR1 waybar && hidden=1
            ;;
        fullscreen\>\>0)
            [ "$hidden" -eq 1 ] && pkill -SIGUSR1 waybar && hidden=0
            ;;
    esac
done
