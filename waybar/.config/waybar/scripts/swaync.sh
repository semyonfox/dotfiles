#!/usr/bin/env bash
set -euo pipefail

signal_waybar() {
  pkill -RTMIN+10 waybar 2>/dev/null || true
}

state_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-swaync"
unread_file="$state_dir/unread"
local_root="${SWAYNC_LOCAL_ROOT:-$HOME/.local/opt/swaync-test/root}"

read_unread() {
  if [[ -r "$unread_file" ]]; then
    read -r value < "$unread_file" || value=0
    [[ "$value" =~ ^[0-9]+$ ]] && printf '%s\n' "$value" && return
  fi
  printf '0\n'
}

write_unread() {
  mkdir -p "$state_dir"
  printf '%s\n' "$1" > "$unread_file"
}

if command -v swaync-client >/dev/null 2>&1; then
  client="$(command -v swaync-client)"
else
  client="$local_root/usr/bin/swaync-client"
  export LD_LIBRARY_PATH="$local_root/usr/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export XDG_DATA_DIRS="$local_root/usr/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  export XDG_CONFIG_DIRS="$local_root/etc/xdg:${XDG_CONFIG_DIRS:-/etc/xdg}"
  export GSETTINGS_SCHEMA_DIR="$local_root/usr/share/glib-2.0/schemas"
fi

case "${1:-status}" in
  receive)
    unread="$(read_unread)"
    write_unread "$((unread + 1))"
    signal_waybar
    exit 0
    ;;
esac

if [[ ! -x "$client" ]]; then
  printf '{"text":"","tooltip":"SwayNC client not found","class":"unavailable"}\n'
  exit 0
fi

client_timeout=1s

case "${1:-status}" in
  open|toggle)
    write_unread 0
    timeout "$client_timeout" "$client" -op -sw >/dev/null 2>&1 || true
    signal_waybar
    ;;
  clear)
    timeout "$client_timeout" "$client" --close-all >/dev/null 2>&1 || true
    write_unread 0
    signal_waybar
    ;;
  dnd)
    timeout "$client_timeout" "$client" -d -sw >/dev/null 2>&1 || true
    signal_waybar
    ;;
  status|bell|info)
    history_count="$(timeout "$client_timeout" "$client" --count 2>/dev/null || true)"
    dnd="$(timeout "$client_timeout" "$client" --get-dnd 2>/dev/null || true)"
    unread="$(read_unread)"

    if [[ ! "$history_count" =~ ^[0-9]+$ ]]; then
      printf '{"text":"","tooltip":"SwayNC is not running","class":"unavailable"}\n'
      exit 0
    fi

    dnd_label="off"
    if [[ "$dnd" == "true" ]]; then
      dnd_label="on"
    fi

    if (( unread > 0 )); then
      icon=""
      text="$icon  $unread"
      state="unread"
    else
      icon=""
      text="$icon"
      state="read"
    fi

    if [[ "$dnd" == "true" ]]; then
      state="${state}-dnd"
    fi

    printf '{"text":"%s","tooltip":"Notification center\\nUnread: %s\\nHistory: %s\\nDo Not Disturb: %s","class":"%s"}\n' \
      "$text" "$unread" "$history_count" "$dnd_label" "$state"
    ;;
  *)
    printf 'usage: %s [status|open|receive|clear|dnd]\n' "$0" >&2
    exit 2
    ;;
esac
