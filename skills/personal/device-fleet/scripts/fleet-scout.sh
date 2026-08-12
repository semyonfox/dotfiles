#!/usr/bin/env bash
set -uo pipefail

section() {
  printf '\n## %s\n' "$1"
}

run() {
  printf '\n$ %s\n' "$*"
  "$@" 2>&1 || true
}

run_sanitized() {
  printf '\n$ %s\n' "$*"
  "$@" 2>&1 | sed -E 's/[[:alnum:]._%+-]+@[[:alnum:].-]*/[account]/g' || true
}

physical_net() {
  ip -brief addr 2>/dev/null | awk '$1 ~ /^(lo|en|eth|wl|ww|tailscale|tun|wg)/ { print }'
}

fleet_routes() {
  ip route 2>/dev/null | awk '/^default/ || / dev (en|eth|wl|ww|tailscale|tun|wg)/ { print }'
}

fleet_neighbors() {
  ip neigh show 2>/dev/null | awk '$0 ~ / dev (en|eth|wl|ww|tailscale|tun|wg)/ { print }'
}

tcp_check() {
  local host="$1"
  local port="${2:-22}"
  if timeout 3 bash -c "</dev/tcp/${host}/${port}" >/dev/null 2>&1; then
    printf '%s:%s open\n' "$host" "$port"
  else
    printf '%s:%s closed_or_timeout\n' "$host" "$port"
  fi
}

remote_probe() {
  local target="$1"
  printf '\n### %s\n' "$target"
  ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$target" '
    printf "host="; hostname
    printf "user="; whoami
    printf "kernel="; uname -a
    if command -v hostnamectl >/dev/null 2>&1; then
      hostnamectl 2>/dev/null | sed -n "s/^  *Operating System: /os=/p;s/^  *Hardware Model: /model=/p;s/^  *Chassis: /chassis=/p"
    fi
    printf "tailscale="; command -v tailscale >/dev/null 2>&1 && tailscale ip -4 2>/dev/null || echo unavailable
    printf "tmux="; command -v tmux >/dev/null 2>&1 && tmux -V || echo unavailable
    printf "codex="; command -v codex >/dev/null 2>&1 && codex --version 2>/dev/null || echo unavailable
    printf "node="; command -v node >/dev/null 2>&1 && node --version || echo unavailable
    printf "npx="; command -v npx >/dev/null 2>&1 && npx --version || echo unavailable
    printf "docker="; command -v docker >/dev/null 2>&1 && docker --version || echo unavailable
    printf "ip=\n"; ip -brief addr 2>/dev/null | sed -n "1,12p" || true
  ' 2>&1 || true
}

printf '# Fleet scout report\n'
date -Is

section "Local host"
run hostnamectl
printf '\n$ physical_net\n'
physical_net || true
printf '\n$ fleet_routes\n'
fleet_routes || true

section "SSH config"
if [[ -r "$HOME/.ssh/config" ]]; then
  sed -n '1,240p' "$HOME/.ssh/config"
else
  printf 'No readable ~/.ssh/config\n'
fi

section "Tailscale"
if command -v tailscale >/dev/null 2>&1; then
  run_sanitized tailscale status
  run tailscale ip -4
  run tailscale serve status
else
  printf 'tailscale unavailable\n'
fi

section "LAN neighbors"
printf '\n$ fleet_neighbors\n'
fleet_neighbors || true

section "TCP/22 reachability"
for host in 10.0.0.5 10.0.0.6 10.0.0.15 10.0.0.17 100.65.148.17 100.77.148.51 100.127.128.15; do
  tcp_check "$host" 22
done

section "MagicDNS resolution"
for name in \
  server.taild7128c.ts.net \
  nas.taild7128c.ts.net \
  semyons-pc.taild7128c.ts.net \
  semyons-laptop.taild7128c.ts.net \
  samsung-sm-a546b.taild7128c.ts.net \
  xiaomi-11t.taild7128c.ts.net; do
  getent hosts "$name" || true
done

if [[ "${FLEET_SSH_PROBE:-0}" == "1" ]]; then
  section "SSH read-only probes"
  remote_probe server
  remote_probe nas
  remote_probe pc
  remote_probe semyon@100.127.128.15
else
  section "SSH read-only probes"
  printf 'Skipped. Re-run with FLEET_SSH_PROBE=1 for remote read-only probes.\n'
fi

section "T3 Code summary"
printf 'For full local or remote T3 startup details, run scripts/t3-audit.sh [ssh-target].\n'
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user show t3-code-headless.service --no-pager \
    -p Id -p LoadState -p ActiveState -p SubState -p UnitFileState -p FragmentPath -p ExecStart 2>/dev/null || true
fi
ss -ltnp 'sport = :3773' 2>/dev/null || ss -ltn 'sport = :3773' 2>/dev/null || true
