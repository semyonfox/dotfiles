# T3 Code Cloudflare Tunnel + LAN DNS pattern

Use when exposing Semyon's host-owned T3 Code headless backend through Cloudflare Tunnel while preserving fast LAN access.

## Known-good topology

- T3 Code stays owned by the user systemd unit: `t3-code-headless.service`.
- Local origin: `http://127.0.0.1:3773`.
- Cloudflare Tunnel is a small Docker-only connector stack under `/home/semyon/server-stacks/t3-code/`.
- Public hostname currently used: `https://t3.semyon.ie`.
- Do not move T3 Code itself into Docker just to match other stacks; that creates a second owner for the same alpha backend/state.

## CLI tunnel workflow

```bash
cloudflared tunnel list
cloudflared tunnel create t3-code
cloudflared tunnel route dns t3-code t3.semyon.ie
TOKEN=$(cloudflared tunnel token t3-code)
mkdir -p /home/semyon/server-stacks/t3-code
umask 077
printf 'TUNNEL_TOKEN=%s\n' "$TOKEN" > /home/semyon/server-stacks/t3-code/stack.env
chmod 600 /home/semyon/server-stacks/t3-code/stack.env
```

Compose shape:

```yaml
services:
  cloudflared:
    container_name: t3-code-cloudflared
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    network_mode: host
    command: tunnel --no-autoupdate --protocol http2 --url http://127.0.0.1:3773 run --token ${TUNNEL_TOKEN}
```

Validate/deploy:

```bash
cd /home/semyon/server-stacks/t3-code
docker compose --env-file stack.env -f stack.yaml config
docker compose --env-file stack.env -f stack.yaml up -d
```

## Verification

```bash
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts --no-pager
curl -fsS -I --max-time 5 http://127.0.0.1:3773/
docker ps --filter name=t3-code-cloudflared --format 'table {{.Names}}\t{{.Status}}'
docker logs --tail=80 t3-code-cloudflared
cloudflared tunnel info t3-code
curl -fsS -I --max-time 20 https://t3.semyon.ie/
```

Healthy signs:

- T3 service active/running with stable restart count.
- Local origin returns `200 OK`.
- `t3-code-cloudflared` is up and `cloudflared tunnel info` shows an active connector.
- Public URL returns `HTTP/2 200` via Cloudflare.

## LAN split-horizon DNS pitfall

Do **not** add `t3.semyon.ie -> 10.0.0.5` in Pi-hole until the local reverse proxy has a vhost for `t3.semyon.ie`.

Observed failure mode: public tunnel worked, direct local origin worked, but forcing local HTTPS with

```bash
curl -kIsS --resolve t3.semyon.ie:443:10.0.0.5 https://t3.semyon.ie/
```

returned Nginx `502` because no matching local Nginx vhost existed. Adding Pi-hole first would have broken LAN clients.

Correct sequence:

1. Create/install an Nginx vhost for `t3.semyon.ie` proxying to `http://127.0.0.1:3773` with websocket/upgrade headers, long read/send timeouts, buffering off, and the existing `/etc/ssl/cloudflare/semyon.ie.*` certs.
2. `nginx -t` and reload Nginx.
3. Verify forced local HTTPS returns T3, not Nginx `502`.
4. Only then add Pi-hole local DNS record `10.0.0.5 t3.semyon.ie` and run `pihole reloaddns`/FTL reload as appropriate.

If sudo is unavailable in the session, write the vhost config into `/home/semyon/server-stacks/t3-code/` and report the exact sudo install commands rather than half-applying local DNS.
