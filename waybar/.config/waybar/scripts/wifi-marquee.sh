#!/usr/bin/env bash
set -euo pipefail

width=14
gap="        "
frame_delay="${WAYBAR_WIFI_MARQUEE_DELAY:-0.15}"
refresh_interval="${WAYBAR_WIFI_REFRESH_INTERVAL:-5}"
state_dir="${XDG_RUNTIME_DIR:-/tmp}/waybar-wifi-marquee"
state_file="$state_dir/state"

mode="disconnected"
label="offline"
tooltip="No connected Wi-Fi or Ethernet"
class="disconnected"
icon=""

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
  mode="disconnected"
  label="offline"
  tooltip="No connected Wi-Fi or Ethernet"
  class="disconnected"
  icon=""

  if ! command -v nmcli >/dev/null 2>&1; then
    tooltip="NetworkManager not available"
    return
  fi

  local wifi_device ssid signal ip4 security
  wifi_device="$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2 == "wifi" && $3 == "connected" {print $1; exit}')"

  if [[ -n "$wifi_device" ]]; then
    ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 == "yes" {sub(/^yes:/, ""); print; exit}')"
    [[ -z "$ssid" ]] && ssid="$(nmcli -g GENERAL.CONNECTION device show "$wifi_device" 2>/dev/null | head -1)"
    [[ -z "$ssid" ]] && ssid="$wifi_device"

    signal="$(nmcli -t -f ACTIVE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1 == "yes" {print $2; exit}')"
    [[ "$signal" =~ ^[0-9]+$ ]] || signal=0

    ip4="$(ip -o -4 addr show "$wifi_device" 2>/dev/null | awk '{print $4; exit}')"
    security="$(nmcli -t -f ACTIVE,SECURITY dev wifi 2>/dev/null | awk -F: '$1 == "yes" {sub(/^yes:/, ""); print; exit}')"

    mode="wifi"
    icon=""
    label="$ssid"
    class="wifi"
    (( signal < 45 )) && class="wifi weak"

    tooltip="Wi-Fi: ${ssid}"$'\n'"Interface: ${wifi_device}"$'\n'"Signal: ${signal}%"
    [[ -n "${ip4:-}" ]] && tooltip+=$'\n'"IPv4: ${ip4}"
    [[ -n "${security:-}" ]] && tooltip+=$'\n'"Security: ${security}"
    return
  fi

  local ethernet_device connection
  ethernet_device="$(nmcli -t -f DEVICE,TYPE,STATE device status 2>/dev/null | awk -F: '$2 == "ethernet" && $3 == "connected" {print $1; exit}')"
  if [[ -n "$ethernet_device" ]]; then
    connection="$(nmcli -g GENERAL.CONNECTION device show "$ethernet_device" 2>/dev/null | head -1)"
    [[ -z "$connection" ]] && connection="$ethernet_device"
    ip4="$(ip -o -4 addr show "$ethernet_device" 2>/dev/null | awk '{print $4; exit}')"

    mode="ethernet"
    icon=""
    label="$ethernet_device"
    class="ethernet"
    tooltip="Ethernet: ${connection}"$'\n'"Interface: ${ethernet_device}"
    [[ -n "${ip4:-}" ]] && tooltip+=$'\n'"IPv4: ${ip4}"
  fi
}

emit_status() {
  if [[ "$mode" == "wifi" ]]; then
    local display="$label" classes="$class"
    if (( ${#label} > width )); then
      display="$(roll_text "$label")"
      classes+=" scrolling"
    fi
    emit "$icon  $display" "$tooltip" "$classes"
  else
    emit "$icon  $label" "$tooltip" "$class"
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
