# Temporary public Slidev deck via Cloudflare Tunnel

Use when Semyon asks to make a local/server-hosted Slidev deck public for a short time under a `*.semyon.ie` hostname.

## Pattern

1. Confirm the local/static deck service is already healthy and identify its origin, usually `http://127.0.0.1:<port>`:

```bash
systemctl --user is-active <deck-static>.service
curl -I --max-time 10 http://127.0.0.1:<port>/
```

2. Create a named Cloudflare Tunnel for the temporary deck:

```bash
cloudflared tunnel create <name>
cloudflared tunnel route dns <name> <host>.semyon.ie
```

Keep the generated credentials file under `~/.cloudflared/` secret. Never paste tunnel credentials or tokens into chat or handover docs.

3. Create a user systemd service that runs the tunnel against the local origin:

```ini
[Unit]
Description=Temporary Cloudflare Tunnel for Slidev deck
After=network.target <deck-static>.service

[Service]
Type=simple
ExecStart=/usr/local/bin/cloudflared tunnel --no-autoupdate --url http://127.0.0.1:<port> run <name>
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

4. Enable and verify:

```bash
systemctl --user daemon-reload
systemctl --user enable --now <name>-cloudflared.service
systemctl --user is-active <name>-cloudflared.service
curl -I --max-time 20 https://<host>.semyon.ie/
curl -I --max-time 20 https://<host>.semyon.ie/<important-static-asset>
```

5. Open the public URL in a browser and visually confirm it renders the deck, not a Cloudflare/error interstitial. For Slidev, checking `/` plus one rendered diagram/SVG asset catches most tunnel/static-path issues.

6. Update the project handover with:

- public URL
- local origin
- tunnel name
- systemd service name/path
- verification results
- explicit stop/remove commands
- reminder not to leak `~/.cloudflared` credentials

## Stop/remove

Stop public exposure but keep tunnel/DNS for later:

```bash
systemctl --user disable --now <name>-cloudflared.service
```

Permanent cleanup, after confirming the deck should no longer be public:

```bash
systemctl --user disable --now <name>-cloudflared.service
systemctl --user disable --now <deck-static>.service   # if this was only for temporary hosting
rm -f ~/.config/systemd/user/<name>-cloudflared.service
rm -f ~/.config/systemd/user/<deck-static>.service      # if temporary
systemctl --user daemon-reload
cloudflared tunnel delete --force <name>
rm -f ~/.cloudflared/<tunnel-id>.json
```

On current `cloudflared` builds, `cloudflared tunnel route dns` may only create/overwrite DNS routes and not provide a `delete` subcommand. Deleting the named tunnel with `--force` removes the Cloudflare Tunnel dashboard object and stops public service once the connector is gone. Verify with `cloudflared tunnel list` and a public `curl`; if a stale DNS CNAME remains and must be removed from the DNS dashboard, use Cloudflare's DNS UI/API carefully for only that hostname.

## Pitfalls

- Do not expose a Slidev dev server publicly if a built static service is already available; prefer the static `dist` server for interview/share links.
- Do not stop after `curl /` succeeds. Verify at least one asset path, especially diagrams under `/diagrams/rendered/...`.
- Cloudflared may print ICMP proxy permission warnings under user systemd; those are usually harmless for HTTP tunnel serving if the tunnel registers connections and HTTPS returns 200.
- Do not delete or modify existing long-lived tunnels when making a temporary deck public. Use a named temporary tunnel and document how to stop it.
