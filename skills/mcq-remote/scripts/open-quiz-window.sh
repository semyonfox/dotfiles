#!/usr/bin/env bash
# use the normal zen session so existing cookies and logins stay available
set -euo pipefail

wl_socket=$(hyprctl instances -j | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["wl_socket"])')
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=$wl_socket
export DBUS_SESSION_BUS_ADDRESS=unix:path=$XDG_RUNTIME_DIR/bus
export XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=Hyprland MOZ_ENABLE_WAYLAND=1

zen-browser --new-window about:blank </dev/null >/dev/null 2>&1 &
echo "quiz window requested in the normal Zen session, verify it on the desktop"
