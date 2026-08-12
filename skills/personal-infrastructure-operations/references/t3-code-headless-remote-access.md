# T3 Code headless remote-access notes

Use when T3 Code works intermittently, disconnects from a server, or the user is trying to run it as a persistent backend.

## Durable lessons

- Treat T3 Code as alpha. Do not over-index on `stable` vs `nightly`; if the user wants nightly, restore/keep nightly and debug the supported remote topology.
- Prefer one canonical owner for the backend, usually a `systemd --user` service for persistent server use.
- Avoid mixing the desktop-managed SSH launch flow with a persistent systemd-owned server. The SSH launcher can leave many `sshd: semyon@notty` sessions and cause confusing reconnect/resource churn.
- For hosted web clients (`https://app.t3.codes`) or any HTTPS-origin browser page, the backend must be reachable as HTTPS/WSS. Plain `http://LAN:3773` or `ws://LAN:3773` may be blocked by browser mixed-content rules.
- Tailscale Serve is the clean headless path: bind T3 locally and expose HTTPS on the Tailnet.

## Upstream-documented patterns

Headless CLI over Tailnet IP:

```bash
npx t3 serve --host "$(tailscale ip -4)"
```

Tailscale HTTPS endpoint:

```bash
npx t3 serve --tailscale-serve
# or custom HTTPS port
npx t3 serve --tailscale-serve --tailscale-serve-port 8444
```

Persistent systemd-style command Semyon used successfully:

```bash
t3 serve \
  --host 127.0.0.1 \
  --port 3773 \
  --base-dir /home/semyon/.t3-code \
  --no-browser \
  --tailscale-serve \
  --tailscale-serve-port 8444 \
  /home/semyon
```

Then pair via a generated HTTPS URL:

```bash
t3 auth pairing create \
  --base-dir /home/semyon/.t3-code \
  --ttl 1h \
  --label t3-server \
  --base-url https://<machine>.<tailnet>.ts.net:8444
```

## Verification checklist

```bash
t3 --version
systemctl --user show t3-code-headless.service -p MainPID -p NRestarts -p ActiveState -p SubState --no-pager
ss -ltnp '( sport = :3773 or sport = :3774 or sport = :4001 )'
tailscale serve status
curl -fsS -I --max-time 5 http://127.0.0.1:3773/
ps -eo cmd | grep -E '^sshd: semyon@notty' | wc -l
journalctl --user -u t3-code-headless.service --since '2 minutes ago' --no-pager
```

Healthy signs:

- exactly one T3 listener on the intended interface/port
- `NRestarts=0` after the last intentional restart
- Tailscale Serve proxies to `http://127.0.0.1:3773`
- no growing pile of `sshd: semyon@notty` sessions
- local HTTP probe returns `200 OK`

## User interaction note

When Semyon is frustrated about a dev server repeatedly disconnecting, bias toward active remediation and concise reporting. Do the inspection/fix/verify loop first; explain after there is real state to report.
