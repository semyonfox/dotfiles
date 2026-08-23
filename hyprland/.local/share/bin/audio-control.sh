#!/usr/bin/env bash

ACTION="${1:-status}"
STEP="${2:-5}"

if ! [[ "$STEP" =~ ^[0-9]+$ ]]; then
  STEP=5
fi

get_default_sink() {
  pactl info | awk -F': ' '/^Default Sink:/{print $2; exit}'
}

sink_name_from_id() {
  local sink_id="$1"
  pactl list short sinks | awk -v id="$sink_id" '$1 == id {print $2; exit}'
}

get_target_sink() {
  local input_sink_id sink

  input_sink_id=$(pactl list short sink-inputs | awk 'NR==1 {print $2}')
  if [[ -n "$input_sink_id" ]]; then
    sink=$(sink_name_from_id "$input_sink_id")
    if [[ -n "$sink" ]]; then
      printf '%s\n' "$sink"
      return
    fi
  fi

  sink=$(pactl list short sinks | awk '$2 ~ /^bluez_output\./ {print $2; exit}')
  if [[ -n "$sink" ]]; then
    printf '%s\n' "$sink"
    return
  fi

  get_default_sink
}

get_sink_description() {
  local sink="$1"
  pactl list sinks | awk -v target="$sink" '
    $1 == "Name:" {name=$2}
    $1 == "Description:" && name == target {
      $1=""
      sub(/^ /, "")
      print
      exit
    }
  '
}

get_sink_state() {
  local sink="$1"
  pactl list short sinks | awk -v target="$sink" '$2 == target {print $NF; exit}'
}

get_sink_volume() {
  local sink="$1"
  pactl get-sink-volume "$sink" 2>/dev/null | awk -F'/' '
    NR == 1 {
      gsub(/ /, "", $2)
      gsub(/%/, "", $2)
      print $2 + 0
      exit
    }
  '
}

get_sink_muted() {
  local sink="$1"
  pactl get-sink-mute "$sink" 2>/dev/null | awk '{print $2}'
}

move_inputs_to_sink() {
  local sink="$1"
  while read -r input_id _; do
    [[ -n "$input_id" ]] && pactl move-sink-input "$input_id" "$sink" >/dev/null 2>&1 || true
  done < <(pactl list short sink-inputs)
}

MAX_VOLUME=150

adjust_volume() {
  local mode="$1"
  local sink current new
  sink=$(get_target_sink)
  [[ -z "$sink" ]] && exit 0

  pactl set-default-sink "$sink" >/dev/null 2>&1 || true

  if [[ "$mode" == "up" ]]; then
    current=$(get_sink_volume "$sink")
    [[ -z "$current" ]] && current=0
    new=$(( current + STEP ))
    (( new > MAX_VOLUME )) && new=$MAX_VOLUME
    pactl set-sink-volume "$sink" "${new}%" >/dev/null 2>&1
  else
    pactl set-sink-volume "$sink" "-${STEP}%" >/dev/null 2>&1
  fi
}

toggle_mute() {
  local sink
  sink=$(get_target_sink)
  [[ -z "$sink" ]] && exit 0

  pactl set-default-sink "$sink" >/dev/null 2>&1 || true
  pactl set-sink-mute "$sink" toggle >/dev/null 2>&1
}

cycle_sink() {
  local current next index=0
  local sinks=()

  mapfile -t sinks < <(pactl list short sinks | awk '{print $2}')
  [[ ${#sinks[@]} -eq 0 ]] && exit 0

  current=$(get_target_sink)
  for i in "${!sinks[@]}"; do
    if [[ "${sinks[$i]}" == "$current" ]]; then
      index=$i
      break
    fi
  done

  next="${sinks[$(((index + 1) % ${#sinks[@]}))]}"
  pactl set-default-sink "$next" >/dev/null 2>&1 || true
  move_inputs_to_sink "$next"
}

escape_json() {
  local text="$1"
  text=${text//\\/\\\\}
  text=${text//\"/\\\"}
  text=${text//$'\n'/\\n}
  printf '%s' "$text"
}

print_status() {
  local sink default_sink desc state volume muted kind icon class text tooltip

  sink=$(get_target_sink)
  default_sink=$(get_default_sink)

  if [[ -z "$sink" ]]; then
    printf '{"text":"%s","tooltip":"%s","class":"off"}\n' "N/A" "No output sinks"
    return
  fi

  desc=$(get_sink_description "$sink")
  [[ -z "$desc" ]] && desc="$sink"

  state=$(get_sink_state "$sink")
  [[ -z "$state" ]] && state="UNKNOWN"

  volume=$(get_sink_volume "$sink")
  [[ -z "$volume" ]] && volume=0

  muted=$(get_sink_muted "$sink")
  [[ -z "$muted" ]] && muted="false"

  if [[ "$sink" =~ ^bluez_output\. ]]; then
    kind="Bluetooth"
  elif [[ "$sink" == *"HDMI"* || "$sink" == *"hdmi"* ]]; then
    kind="HDMI"
  else
    kind="Speaker"
  fi

  if [[ "$muted" == "yes" ]]; then
    icon=$'\U000f075F'
    class="muted"
  elif (( volume == 0 )); then
    icon=$'\U000f057F'
    class="low"
  elif (( volume < 50 )); then
    icon=$'\U000f0580'
    class="medium"
  else
    icon=$'\U000f057E'
    class="high"
  fi

  if [[ "$sink" =~ ^bluez_output\. ]]; then
    class="${class} bluetooth"
  fi

  text="$icon  ${volume}%"
  tooltip="Output: ${desc}"$'\n'"Type: ${kind}"$'\n'"State: ${state}"
  if [[ "$sink" == "$default_sink" ]]; then
    tooltip+=$'\n'"Default: yes"
  else
    tooltip+=$'\n'"Default: no"
  fi

  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' \
    "$(escape_json "$text")" \
    "$(escape_json "$tooltip")" \
    "$(escape_json "$class")"
}

case "$ACTION" in
  status)
    print_status
    ;;
  up)
    adjust_volume up
    ;;
  down)
    adjust_volume down
    ;;
  mute)
    toggle_mute
    ;;
  cycle)
    cycle_sink
    ;;
  *)
    print_status
    ;;
esac
