# T3 Code headless server: systemd, SSH launcher conflicts, and Tailscale Serve

Use when T3 Code on `server` is repeatedly disconnecting, spawning SSH sessions, or remote links fail.

## Known-good ownership model

Prefer one canonical owner for the long-running T3 server:

```bash
systemctl --user status t3-code-headless.service
systemctl --user enable t3-code-headless.service
systemctl --user start t3-code-headless.service
```

The stable service shape observed:

```ini
[Service]
WorkingDirectory=/home/semyon
Environment=HOME=/home/semyon
Environment=PATH=/home/semyon/.local/bin:/home/semyon/.nvm/versions/node/v24.16.0/bin:/usr/local/bin:/usr/bin:/bin
Environment=T3CODE_HOME=/home/semyon/.t3-code
Environment=T3CODE_NO_BROWSER=1
ExecStart=/home/semyon/.local/bin/t3 serve --host 0.0.0.0 --port 3773 --base-dir /home/semyon/.t3-code --no-browser /home/semyon
Restart=always
RestartSec=5
KillSignal=SIGINT
TimeoutStopSec=30
```

Linger should be enabled so the user service starts at boot:

```bash
loginctl show-user semyon -p Linger -p State
```

## Desktop SSH launcher conflict pattern

The T3 desktop app can launch a separate managed SSH server under:

```text
~/.t3-code/ssh-launch/<id>/managed
~/.t3-code/ssh-launch/<id>/pid
~/.t3-code/ssh-launch/<id>/port
~/.t3-code/ssh-launch/<id>/run-t3.sh
~/.t3-code/ssh-launch/<id>/server.log
```

If it is flapping, symptoms include:

- many `sshd: semyon@notty` sessions from the same peer
- repeated `Listening on http://127.0.0.1:3773` entries in `server.log`
- one or more `node ... t3 serve --host 127.0.0.1 --port 3773` processes with parent `systemd,1`
- `t3-code-headless.service` enabled but inactive while the SSH launcher owns the port

Stabilize by making the ownership single-source:

1. Stop or disconnect the desktop SSH-managed connection if possible.
2. Kill only the SSH-launched T3 processes, not unrelated SSH TTY sessions.
3. Start the systemd user service.
4. Verify exactly one listener on `0.0.0.0:3773`:

```bash
pgrep -af 't3 serve|codex app-server'
ss -ltnp '( sport = :3773 or sport = :3774 )'
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts --no-pager
curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' -m 5 http://127.0.0.1:3773/
```

## Update restart watcher

A simple update watcher can restart the service after the T3 binary changes:

```ini
# ~/.config/systemd/user/t3-code-headless-update.path
[Unit]
Description=Watch T3 Code CLI for updates

[Path]
PathChanged=/home/semyon/.local/bin/t3
PathChanged=/home/semyon/.nvm/versions/node/v24.16.0/bin/t3
PathChanged=/home/semyon/.nvm/versions/node/v24.16.0/lib/node_modules/t3/dist/bin.mjs
Unit=t3-code-headless-restart.service

[Install]
WantedBy=default.target
```

```ini
# ~/.config/systemd/user/t3-code-headless-restart.service
[Unit]
Description=Restart T3 Code headless server after binary update

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl --user try-restart t3-code-headless.service
```

Enable with:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless-update.path
```

## Remote links: LAN, T3 Connect, and Tailscale

Local/LAN pairing can be issued with:

```bash
t3 auth pairing create --base-dir /home/semyon/.t3-code --ttl 1h --label '<label>' --base-url http://10.0.0.5:3773 --json
```

T3 Connect cloud remote is separate. Check it with:

```bash
t3 connect status --base-dir /home/semyon/.t3-code --json
```

If `desired/authenticated/linked` are false, the cloud remote link will not work until `t3 connect link --base-dir /home/semyon/.t3-code` is completed interactively in a browser.

For Tailscale remote access, avoid port 443 on this server because host Nginx/Cloudflare-origin config may already own it and return a misleading 502. Use a non-conflicting HTTPS port, e.g.:

```bash
tailscale serve --https=8444 --bg 3773
tailscale serve status
t3 auth pairing create --base-dir /home/semyon/.t3-code --ttl 1h --label '<label>' --base-url https://server.taild7128c.ts.net:8444 --json
```

Verify from the server with an explicit resolve if local MagicDNS is not resolving:

```bash
curl -k -sS -I -m 8 --resolve server.taild7128c.ts.net:8444:100.118.61.122 https://server.taild7128c.ts.net:8444/
```

## Pitfalls

- Do not run both the desktop SSH launcher and `t3-code-headless.service` as independent owners of the same port/state DB; this causes disconnect loops, SSH session churn, and SQLite lock noise.
- If the preflight guard scans full command lines for the literal text `t3 serve`, diagnostic shell commands can false-positive and block startup. Filter by real process `comm` values such as `node`, `t3`, or `flock`, not arbitrary bash/hermes command text.
- `server-runtime.json` may advertise `origin: http://127.0.0.1:3773` even when the service binds `0.0.0.0`; verify with real `curl` probes rather than trusting only the file.
- `t3 connect link` prints a browser authorization URL and waits for callback; do not assume it completed if the command times out or is killed before browser auth finishes.
- When creating systemd unit files, put `StartLimitIntervalSec=0` in `[Unit]`, not `[Service]`, for this systemd version.
