# T3 Code SSH disconnect triage

Use this when T3 Code Desktop reports repeated `disconnected` while it is connected to a remote host via SSH.

## What to inspect

1. Identify the managed T3 launch directory and current process:
   ```bash
   for d in ~/.t3-code/ssh-launch/*; do
     [ -d "$d" ] || continue
     echo "-- $d"
     for f in pid port managed; do [ -e "$d/$f" ] && printf '%s=' "$f" && tr -d '\n' < "$d/$f" && echo; done
   done
   pgrep -af 't3 serve|codex app-server'
   ```

2. Check whether multiple T3 servers are alive or stale ports remain:
   ```bash
   ss -ltnp '( sport = :3773 or sport = :3774 )' 2>/dev/null
   for pid in $(pgrep -f 't3 serve'); do
     echo "-- pid $pid"
     ps -p "$pid" -o pid,ppid,lstart,etime,%cpu,%mem,cmd --no-headers
     echo -n 'stdout='; readlink -f /proc/$pid/fd/1 2>/dev/null
   done
   ```

3. Read the active server log and search for restart/disconnect/config signals:
   ```bash
   log=$(readlink -f /proc/$(cat ~/.t3-code/ssh-launch/*/pid 2>/dev/null | tail -1)/fd/1 2>/dev/null || true)
   [ -n "$log" ] && grep -n 'Listening on\|T3 Code server is ready\|SchemaError\|websocket\|disconnect\|VCS remote status refresh failed' "$log" | tail -80
   ```

4. Check SSH churn from the desktop app:
   ```bash
   journalctl -u ssh --since '10 minutes ago' --no-pager 2>/dev/null | egrep 'session opened|session closed' | tail -80
   ss -tan sport = :22 | awk 'NR>1{print $1,$4,$5}' | sort | uniq -c | sort -nr | head
   ```

5. Probe the currently managed port directly:
   ```bash
   port=$(cat ~/.t3-code/ssh-launch/*/port 2>/dev/null | tail -1)
   curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' -m 3 "http://127.0.0.1:${port}/"
   ```

## Known durable failure pattern

A bad user config can make T3 Desktop repeatedly relaunch the remote server over SSH. In one incident:

- `~/.t3-code/userdata/keybindings.json` contained an invalid command: `sidebar.toggle`.
- The server log showed `SchemaError ... got "sidebar.toggle"`.
- The desktop app opened many SSH sessions and multiple/stale T3 servers accumulated.
- The fix was to remove the invalid keybinding, let/trigger the managed server relaunch, then kill the stale older server tree.

## Recovery pattern

- Fix the config error first; otherwise the desktop app may immediately recreate the loop.
- Prefer leaving the process whose pid/port matches `~/.t3-code/ssh-launch/<id>/pid` and killing only older stale `t3 serve` trees.
- If the intended architecture is **headless/server-owned T3**, make systemd the only owner instead of letting Desktop SSH manage the process. Stop the SSH-launched `127.0.0.1:<port>` server, clear stale `sshd: <user>@notty` sessions if they are piling up, then start the user unit and verify it owns the port.
- Verify only one T3 listener remains, the selected port answers HTTP 200, and SSH session-open churn stops for a short watch window.

Example stale cleanup:

```bash
managed_pid=$(cat ~/.t3-code/ssh-launch/*/pid 2>/dev/null | tail -1)
for pid in $(pgrep -f 't3 serve'); do
  [ "$pid" = "$managed_pid" ] && continue
  pkill -TERM -P "$pid" || true
  kill -TERM "$pid" || true
  sleep 2
  kill -0 "$pid" 2>/dev/null && { pkill -KILL -P "$pid" || true; kill -KILL "$pid" || true; }
done
ss -ltnp '( sport = :3773 or sport = :3774 )' 2>/dev/null
```

## Headless systemd ownership pattern

When the user expects T3 to launch on boot and restart after CLI updates, prefer a user systemd unit plus a path unit instead of Desktop SSH management.

Service shape:

```ini
# ~/.config/systemd/user/t3-code-headless.service
[Unit]
Description=T3 Code headless server
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=/home/<user>
Environment=HOME=/home/<user>
Environment=PATH=/home/<user>/.local/bin:/home/<user>/.nvm/versions/node/<version>/bin:/usr/local/bin:/usr/bin:/bin
Environment=T3CODE_HOME=/home/<user>/.t3-code
Environment=T3CODE_NO_BROWSER=1
ExecStart=/home/<user>/.local/bin/t3 serve --host 0.0.0.0 --port 3773 --base-dir /home/<user>/.t3-code --no-browser /home/<user>
Restart=always
RestartSec=5
KillSignal=SIGINT
TimeoutStopSec=30

[Install]
WantedBy=default.target
```

Make sure linger is enabled so the user unit survives logout/reboot:

```bash
loginctl show-user "$USER" -p Linger -p State
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless.service
```

For update-triggered restarts, create a `*.path` unit watching the actual T3 CLI target(s), not just the symlink:

```ini
# ~/.config/systemd/user/t3-code-headless-restart.service
[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl --user try-restart t3-code-headless.service
```

```ini
# ~/.config/systemd/user/t3-code-headless-update.path
[Path]
PathChanged=/home/<user>/.local/bin/t3
PathChanged=/home/<user>/.nvm/versions/node/<version>/bin/t3
PathChanged=/home/<user>/.nvm/versions/node/<version>/lib/node_modules/t3/dist/bin.mjs
Unit=t3-code-headless-restart.service

[Install]
WantedBy=default.target
```

Enable the watcher:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless-update.path
```

Verify canonical ownership:

```bash
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts
ss -ltnp '( sport = :3773 or sport = :3774 )' 2>/dev/null
curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' http://127.0.0.1:3773/
```

## Remote link modes

Do not conflate the three ways to reach T3:

1. **LAN direct:** service listens on `0.0.0.0:3773`; pair with `http://<LAN-IP>:3773/pair#token=...`.
2. **Tailscale Serve:** tailnet HTTPS proxy to local T3; useful when LAN IP is unavailable. Check existing 443 ownership before using the default HTTPS port.
3. **T3 Connect cloud relay:** separate auth/link state; `t3 connect status --base-dir ~/.t3-code --json` must show `desired/authenticated/linked` true for cloud remote links to work.

Useful checks:

```bash
t3 connect status --base-dir ~/.t3-code --json
t3 auth pairing create --base-dir ~/.t3-code --ttl 1h --label repair --base-url http://<host-or-tailnet-url> --json
tailscale serve status
```

If `tailscale serve` on `https://<node>.<tailnet>/` returns an unexpected Nginx/Cloudflare-origin `502`, port 443 is probably already owned by another local web server. Use a non-conflicting HTTPS port such as 8444:

```bash
tailscale serve --https=8444 --bg 3773
t3 auth pairing create --base-dir ~/.t3-code --ttl 1h --label tailnet --base-url https://<node>.<tailnet>:8444 --json
```

Verify with a real probe from the host or another tailnet node:

```bash
curl -k -I https://<node>.<tailnet>:8444/
```

## Pitfalls

- Do not assume SSH itself is broken just because T3 says disconnected. Look for repeated short-lived SSH sessions caused by the desktop app relaunch loop.
- Do not kill every `t3 serve` blindly; use the managed pid/port files to distinguish current from stale.
- Missing provider CLIs such as Cursor/Grok health-check warnings are usually non-fatal noise unless the user is specifically trying to use those providers.
- VCS remote-status failures can be noisy and unrelated; note them, but do not treat them as the disconnect cause unless they coincide with process crashes/restarts.
