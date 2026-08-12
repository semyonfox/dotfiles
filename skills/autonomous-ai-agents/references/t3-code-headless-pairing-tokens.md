# T3 Code Headless Pairing Tokens

Use this when Semyon asks for a “T3 Code pairing code/stat” for an already-running headless T3 Code server.

## Fast path

1. Check whether a T3 Code headless server is already running/listening on the expected port (usually `3773`) before starting another copy.
2. Use the CLI auth control plane to mint a short-lived token:

```bash
t3 auth pairing create \
  --ttl 15m \
  --label "discord-$(date +%Y%m%d-%H%M%S)" \
  --base-url http://<reachable-host-or-ip>:3773 \
  --json
```

3. Prefer a LAN/Tailscale/real reachable address in `--base-url`, not `server` or `localhost`, unless the receiving client is definitely on the same host.
4. If you generated a token with a bad public URL, revoke it and mint a clean replacement:

```bash
t3 auth pairing revoke <pairing-id>
```

5. Treat the resulting `credential` / `pairUrl` as sensitive because the default scopes include orchestration and terminal operation. Do **not** post it into a public/server Discord thread. Send it privately to Semyon (for example WhatsApp) or ask for a safe delivery target if no private channel is obvious.

## Useful checks

```bash
command -v t3
ps -eo pid,cmd | grep -E '([n]px|[t]3|node).*t3|[t]3code|:3773' || true
ss -ltnp 2>/dev/null | grep -E '3773|3774' || true
curl -fsS -I http://127.0.0.1:3773/ | head
hostname -I
```

## Notes

- `t3 serve` prints headless pairing details on startup, but for a long-running managed service it is cleaner to issue fresh tokens via `t3 auth pairing create` rather than restarting the server just to see a code.
- Keep TTLs short for ad-hoc pairing codes.
- `t3 auth pairing list --json` shows active pairing links without revealing secrets.
