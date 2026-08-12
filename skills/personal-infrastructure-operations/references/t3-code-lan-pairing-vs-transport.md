# T3 Code LAN pairing vs transport stability

Session-derived notes for T3 Code headless/remote setups.

## Durable lessons

- `t3 auth pairing create` / `/pair#token=...` only authenticates a client and creates a session. It does **not** create a tunnel and does **not** stabilize the network path.
- After pairing, the client still needs a stable HTTP/WebSocket route to the backend URL (for example `http://10.0.0.5:3773`). If the device leaves LAN, switches between Wi-Fi and mobile data, or roams between cellular towers, the WebSocket can drop even though the T3 service is healthy.
- LAN bind is valid when Semyon explicitly wants same-network access. Do not replace it with Tailscale just because Tailscale is technically cleaner; explain the tradeoff and preserve the requested LAN bind unless he asks for mobile/roaming access.
- Tailscale is specifically better when the client must survive changing networks/mobile data because it provides a stable private overlay path. It is not automatically better for plain same-Wi-Fi LAN use.
- SSH port forwarding over mobile data can be broken by tower roaming/NAT rebinding. If using SSH anyway, add keepalives, but do not pretend keepalives make it as robust as an overlay/tunnel.

## Recommended LAN headless service shape

```ini
ExecStart=/home/semyon/.local/bin/t3 serve --host 0.0.0.0 --port 3773 --base-dir /home/semyon/.t3-code --no-browser /home/semyon
```

Generate a short-lived LAN pairing URL:

```bash
t3 auth pairing create \
  --base-dir /home/semyon/.t3-code \
  --ttl 15m \
  --label lan \
  --base-url http://10.0.0.5:3773
```

For ad-hoc debugging, it is acceptable to give Semyon the fresh pairing URL/token if he explicitly asks for it in the current chat, but prefer short TTLs.

## Diagnostics for disconnects

Server health:

```bash
systemctl --user show t3-code-headless.service -p MainPID -p NRestarts -p ActiveState -p SubState --no-pager
ss -ltnp '( sport = :3773 )'
curl -fsS -I --max-time 5 http://127.0.0.1:3773/
```

Transport path clues:

```bash
ss -tanp '( sport = :3773 or dport = :3773 )'
```

Interpretation:

- Peer in same LAN subnet (e.g. `10.0.0.x`) -> LAN path.
- Peer in `100.x.x.x` -> Tailscale/CGNAT-style path; not pure LAN.
- Many `TIME-WAIT` / `FIN-WAIT-2` with stable service and `NRestarts=0` -> likely client/network path churn, not T3 process crash.

SSH launcher leak check:

```bash
ps -eo pid,ppid,stat,etime,args | awk '/sshd: semyon@notty/ && !/awk/ {print}'
```

Kill stale `notty` SSH sessions only when they have no useful child command and systemd is canonical; preserve real `pts/*` shells.

## Avoid

- Do not dump full `t3 auth session list` into chat; it can be enormous and noisy. If needed, filter/summarize counts or only recent sessions.
- Do not switch to Tailscale Serve by default when Semyon asks for LAN bind.
- Do not say pairing will fix disconnects; pairing fixes auth only, not transport.
