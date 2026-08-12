#!/usr/bin/env bash
# Read-only safety inventory for a self-hosted DaVinci Resolve PostgreSQL library.
# Usage: verify-resolve-network-library.sh [lan_ip] [pgadmin_port] [hostname ...]
# Example: verify-resolve-network-library.sh 10.0.0.5 5051 resolve.semyon.ie
set -euo pipefail

lan_ip="${1:-10.0.0.5}"
pgadmin_port="${2:-5051}"
shift $(( $# >= 2 ? 2 : $# )) || true
hosts=("$@")

echo '== PostgreSQL listener on Resolve-required port =='
ss -ltnp "( sport = :5432 )" || true

echo
echo '== Resolve-related containers =='
docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}' \
  | { head -n 1; grep -Ei 'resolve|pgadmin' || true; }

echo
echo '== LAN TCP reachability =='
if command -v pg_isready >/dev/null 2>&1; then
  pg_isready -h "$lan_ip" -p 5432 || true
else
  timeout 5 bash -c "</dev/tcp/$lan_ip/5432" \
    && echo "TCP reachable: $lan_ip:5432" \
    || echo "TCP unavailable: $lan_ip:5432"
fi

echo
echo '== Local pgAdmin health =='
curl --noproxy '*' -sS -I --max-time 10 "http://127.0.0.1:${pgadmin_port}/" \
  | tr -d '\r' | head -n 8 || true

if ((${#hosts[@]})); then
  echo
  echo '== Candidate public DNS records =='
  for host in "${hosts[@]}"; do
    printf '%-40s ' "$host"
    { dig +short CNAME "$host" @1.1.1.1; dig +short A "$host" @1.1.1.1; } \
      | paste -sd ' ' -
  done
fi

echo
echo 'Safety rule: do not publish PostgreSQL itself. A public hostname, if needed,'
echo 'must target loopback-bound pgAdmin and be protected by Cloudflare Access.'
