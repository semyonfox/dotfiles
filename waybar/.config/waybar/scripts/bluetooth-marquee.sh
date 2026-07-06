#!/usr/bin/env bash
set -euo pipefail

width=14
gap="        "
frame_delay="${WAYBAR_BLUETOOTH_MARQUEE_DELAY:-0.15}"
refresh_interval="${WAYBAR_BLUETOOTH_REFRESH_INTERVAL:-5}"
state_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-bluetooth-marquee"
state_file="$state_dir/state"

mode="off"
label=""
tooltip="Bluetooth on, no connected devices"
class="off"
icon="󰂱"

json_escape() {
  local text="$1"
  text=${text//\\/\\\\}
  text=${text//\"/\\\"}
  text=${text//$'\n'/\\n}
  printf '%s' "$text"
}

emit() {
  local text="$1" tip="$2" classes="$3"
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(json_escape "$text")" \
    "$(json_escape "$tip")" \
    "$(json_escape "$classes")"
}

roll_text() {
  local source="$1"
  local source_len=${#source}

  if (( source_len <= width )); then
    printf '%s\n' "$source"
    return
  fi

  mkdir -p "$state_dir"

  local saved_key="" saved_idx="0"
  if [[ -r "$state_file" ]]; then
    IFS=$'\t' read -r saved_key saved_idx < "$state_file" || true
  fi

  local key
  key="$(printf '%s' "$source" | cksum | awk '{print $1}')"
  if [[ "$saved_key" != "$key" || ! "$saved_idx" =~ ^[0-9]+$ ]]; then
    saved_idx=0
  fi

  local loop="${source}${gap}"
  local loop_len=${#loop}
  local doubled="${loop}${loop}"
  local display="${doubled:saved_idx:width}"
  local next_idx=$(( (saved_idx + 1) % loop_len ))

  printf '%s\t%s\n' "$key" "$next_idx" > "$state_file"
  printf '%s\n' "$display"
}

collect_status() {
  mode="off"
  label=""
  tooltip="Bluetooth on, no connected devices"
  class="off"
  icon="󰂱"

  if ! command -v bluetoothctl >/dev/null 2>&1; then
    tooltip="bluetoothctl not available"
    class="unavailable"
    return
  fi

  local controller powered
  controller="$(bluetoothctl show 2>/dev/null || true)"
  if [[ -z "$controller" ]]; then
    tooltip="No Bluetooth controller"
    class="unavailable"
    return
  fi

  powered="$(awk -F': ' '/Powered:/ {print $2; exit}' <<< "$controller")"
  if [[ "$powered" != "yes" ]]; then
    tooltip="Bluetooth disabled"
    class="disabled"
    return
  fi

  local connected=()
  mapfile -t connected < <(bluetoothctl devices Connected 2>/dev/null | sed -n '/^Device /p')
  if (( ${#connected[@]} == 0 )); then
    return
  fi

  local names=() line body mac name
  for line in "${connected[@]}"; do
    body="${line#Device }"
    mac="${body%% *}"
    name="${body#${mac} }"
    [[ -z "$name" || "$name" == "$body" ]] && name="$mac"
    names+=("$name")
  done

  mode="connected"
  label="${names[0]}"
  if (( ${#names[@]} > 1 )); then
    label+=" +$(( ${#names[@]} - 1 ))"
  fi
  tooltip="Bluetooth: connected"
  for name in "${names[@]}"; do
    tooltip+=$'\n'"${name}"
  done
  class="connected"
}

emit_status() {
  if [[ "$mode" == "connected" ]]; then
    local display="$label" classes="$class"
    if (( ${#label} > width )); then
      display="$(roll_text "$label")"
      classes+=" scrolling"
    fi
    emit "$icon  $display" "$tooltip" "$classes"
  else
    emit "" "$tooltip" "$class"
  fi
}

if [[ "${1:-}" == "--stream" ]]; then
  next_refresh=0
  while true; do
    now="$(date +%s)"
    if (( now >= next_refresh )); then
      collect_status
      next_refresh=$(( now + refresh_interval ))
    fi
    emit_status
    sleep "$frame_delay"
  done
fi

collect_status
emit_status
