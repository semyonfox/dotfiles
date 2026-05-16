#!/usr/bin/env bash
# show a lock glyph when mullvad / tailscale / cloudflare warp is up.
# empty text when no vpn — waybar hides empty custom modules.

set -u

active=()

if command -v mullvad >/dev/null 2>&1; then
  status=$(mullvad status 2>/dev/null | head -1)
  if [[ "$status" == Connected* ]]; then
    relay=$(mullvad status 2>/dev/null | awk -F': +' '/Relay:/ {print $2; exit}')
    active+=("Mullvad${relay:+ ($relay)}")
  fi
fi

if command -v tailscale >/dev/null 2>&1; then
  if tailscale status --json 2>/dev/null | grep -q '"BackendState": *"Running"'; then
    exitnode=$(tailscale status --json 2>/dev/null | awk -F'"' '/"ExitNode": *true/{found=1} found && /"HostName"/{print $4; exit}')
    active+=("Tailscale${exitnode:+ ($exitnode)}")
  fi
fi

if command -v warp-cli >/dev/null 2>&1; then
  if warp-cli --accept-tos status 2>/dev/null | grep -q "Status update: Connected"; then
    active+=("Cloudflare WARP")
  fi
fi

if (( ${#active[@]} == 0 )); then
  printf '{"text":"","tooltip":"No VPN","class":"off"}\n'
  exit 0
fi

# icon: mdi-shield-lock for a single vpn, mdi-shield-lock-outline+badge if multiple
if (( ${#active[@]} > 1 )); then
  icon=$'\U000f0565'  # mdi-shield-check — multi vpn active
else
  icon=$'\U000f099D'  # mdi-shield-lock
fi

# escape newlines for json tooltip
tooltip=$(printf '%s\n' "${active[@]}")
tooltip=${tooltip//$'\n'/\\n}

printf '{"text":"%s","tooltip":"%s","class":"on"}\n' "$icon" "${tooltip%\\n}"
