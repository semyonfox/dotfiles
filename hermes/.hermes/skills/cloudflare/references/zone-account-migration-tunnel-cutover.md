# Cloudflare zone account migration + tunnel cutover

Use this when moving a domain between Cloudflare accounts, especially when the site is served through Cloudflare Tunnel.

## Key lessons

- Moving registrar nameservers is **not** the whole migration. Verify the destination zone has all DNS records and that any Cloudflare Tunnel public hostnames point at tunnels connected in the destination account.
- A `cloudflared` origin cert/tunnel token may list/read tunnels but still lack API permission to create zones or write DNS records. Zone creation requires a user API token with `Zone:Zone:Edit` scoped to `All zones` in the destination account. DNS copying requires `Zone:DNS:Edit`.
- If the destination zone already exists, Cloudflare may import/copy some records, but do not assume apex, `www`, or tunnel hostnames are present. Query the new authoritative nameservers directly.
- `cloudflared tunnel route dns` can accidentally create records under the wrong zone if invoked from an account cert whose active zone context is different. Prefer Cloudflare dashboard/API for exact-zone DNS writes when multiple accounts/zones are involved.
- Tunnel tokens are account + tunnel specific. Updating DNS to the personal zone is insufficient if the actual `cloudflared` connector still runs the old/company tunnel token.

## Verification commands

Check registrar and recursive propagation:

```bash
whois example.ie | awk '/Name Server:/ {print}'
for r in 1.1.1.1 8.8.8.8 9.9.9.9; do dig @$r +short NS example.ie; done
```

Check destination authoritative records directly:

```bash
for q in 'example.ie A' 'www.example.ie A' 'dev.example.ie A' 'example.ie MX'; do
  echo "--- $q"
  dig @DEST_NS.cloudflare.com +short $q
 done
```

Check tunnel connector status:

```bash
TUNNEL_ORIGIN_CERT=~/.cloudflared/cert-personal.pem cloudflared tunnel info TUNNEL_NAME
```

For Docker Compose stacks using tunnel tokens in an env file:

```bash
cd /path/to/stack
cp -a stack.env "stack.env.bak-$(date +%Y%m%d-%H%M%S)-before-cf-tunnel-token-rotation"
# edit CLOUDFLARED_*_TUNNEL_TOKEN values
docker compose --env-file stack.env -f stack.yaml up -d cloudflared-prod cloudflared-dev
docker logs --tail 50 cloudflared-container-name
```

Successful logs include `Starting tunnel tunnelID=...`, `Updated to new configuration`, and multiple `Registered tunnel connection` lines.

## Cutover checklist

1. Create/import destination zone in target Cloudflare account.
2. Copy required DNS records: apex, `www`, dev/staging, MX, SPF/DKIM/DMARC, and any verification TXT.
3. Confirm Cloudflare Tunnel public hostnames in the destination account:
   - apex -> correct origin service
   - `www` -> same service if needed
   - dev/staging -> correct dev service
4. Rotate/update running connector tokens so containers/services connect to destination-account tunnels.
5. Restart connectors and verify `cloudflared tunnel info` shows active connections on destination tunnels.
6. Update registrar nameservers.
7. Verify authoritative DNS and HTTP status from outside the origin network.
8. Rotate any tunnel tokens pasted into chats/logs after the incident window closes.
