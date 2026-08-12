# T3 Code Cloudflare Tunnel + LAN split-horizon pattern

Use when exposing Semyon's host-owned T3 Code headless service through Cloudflare while keeping LAN access local.

## Durable topology

- T3 Code itself should stay owned by the user systemd service, not Docker:
  - `t3-code-headless.service`
  - local origin: `http://127.0.0.1:3773`
- Docker owns only the Cloudflare connector stack:
  - stack dir: `/home/semyon/server-stacks/t3-code/`
  - container: `t3-code-cloudflared`
  - public hostname: `https://t3.semyon.ie`
- LAN split-horizon uses host Nginx + Pi-hole:
  - Pi-hole resolves `t3.semyon.ie -> 10.0.0.5`
  - Nginx terminates HTTPS for `t3.semyon.ie`
  - Nginx proxies to `http://127.0.0.1:3773`

This matches the Jellyfin/Immich local-speed pattern: public tunnel for remote, Pi-hole LAN DNS to the server IP, local Nginx vhost to the actual service port.

## Preferred Pi-hole v6 method

Use a dnsmasq include instead of adding new records to generated Pi-hole hosts files.

1. Enable dnsmasq includes:

```bash
docker exec pihole pihole-FTL --config misc.etc_dnsmasq_d true
```

2. Add explicit records under `/etc/dnsmasq.d/99-semyon-lan-overrides.conf`:

```text
address=/jellyfin.semyon.ie/10.0.0.5
address=/immich.semyon.ie/10.0.0.5
address=/t3.semyon.ie/10.0.0.5
```

3. Validate and reload/restart:

```bash
docker exec pihole pihole-FTL dnsmasq-test
docker exec pihole pihole reloaddns
# If stale answers persist, restart the container:
docker restart pihole
```

## Pi-hole stale-backup pitfall

Do not store backup files under `/etc/pihole/hosts/`. Pi-hole/FTL treats files in that directory as hosts sources; `custom.list.backup-*` can keep stale local overrides alive even after `custom.list` and `pihole.toml` are cleaned.

Move backups to `/etc/pihole/config_backups/` or outside the mounted hosts directory, then restart Pi-hole.

Debug sticky records with:

```bash
docker exec pihole sh -lc 'grep -R "hostname" -n /etc/pihole/hosts /etc/dnsmasq.d /etc/pihole/pihole.toml 2>/dev/null || true'
```

## Nginx vhost notes

- Jellyfin vhost: `/etc/nginx/sites-available/jellyfin.semyon.ie` -> `http://10.0.0.5:8096`
- Immich canonical vhost: `/etc/nginx/sites-available/immich.semyon.ie` -> `http://10.0.0.5:2283`
- T3 vhost: `/etc/nginx/sites-available/t3.semyon.ie` -> `http://127.0.0.1:3773`

Prefer `immich.semyon.ie` as the canonical Immich local hostname; avoid reintroducing `photos.semyon.ie` as the primary LAN DNS/vhost.

## Verification

```bash
# DNS
for h in jellyfin.semyon.ie immich.semyon.ie t3.semyon.ie photos.semyon.ie; do
  printf '%-22s ' "$h"
  dig +short @10.0.0.5 "$h" A | paste -sd, -
done

# Local HTTPS via LAN IP
curl -kIsS --resolve jellyfin.semyon.ie:443:10.0.0.5 https://jellyfin.semyon.ie/
curl -kIsS --resolve immich.semyon.ie:443:10.0.0.5 https://immich.semyon.ie/
curl -kIsS --resolve t3.semyon.ie:443:10.0.0.5 https://t3.semyon.ie/

# Public tunnel still works
curl -fsS -I https://t3.semyon.ie/
```

Healthy expected headers:

- Jellyfin: `HTTP/2 302` with `location: web/`
- Immich: `HTTP/2 200`
- T3: `HTTP/2 200`
