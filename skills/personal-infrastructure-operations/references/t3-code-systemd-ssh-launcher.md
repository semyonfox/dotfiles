# T3 Code: systemd service vs desktop SSH launcher

Session pattern: Semyon reported T3 Code constantly disconnecting while the desktop app was connected via SSH. The durable lesson is not a specific PID/token; it is the ownership conflict and verification sequence.

## Symptoms

- T3 desktop app repeatedly reports disconnected.
- Many SSH sessions from the desktop/NAS peer, often `sshd: semyon@notty`.
- T3 launch log shows repeated `Listening on http://127.0.0.1:<port>` and new pairing details.
- A user systemd unit exists but is disabled, failed, inactive, or not the current process owner.
- One process listens on `127.0.0.1:3773`/`3774` from the SSH launcher while the intended headless service should listen on `0.0.0.0:3773`.

## Key files and commands

T3 launch metadata:

```bash
for d in ~/.t3-code/ssh-launch/*; do
  [ -d "$d" ] || continue
  echo "-- $d"
  for f in managed pid port; do
    [ -e "$d/$f" ] && printf '%s=' "$f" && tr -d '\n' < "$d/$f" && echo
  done
done
```

Runtime files:

```bash
sed -n '1p' ~/.t3-code/userdata/server-runtime.json 2>/dev/null
sed -n '1p' ~/.t3/userdata/server-runtime.json 2>/dev/null
```

Owner and port checks:

```bash
pgrep -af 't3 serve|codex app-server'
ss -ltnp '( sport = :3773 or sport = :3774 )'
systemctl --user status t3-code-headless.service --no-pager
systemctl --user is-enabled t3-code-headless.service
```

SSH churn check:

```bash
journalctl -u ssh --since '10 minutes ago' --no-pager \
  | egrep 'session opened|session closed|disconnect|fatal|error|reset|timeout'
ss -tan sport = :22 | awk 'NR>1{print $1,$5}' | sort | uniq -c | sort -nr | head
```

## Good T3 systemd shape

For Semyon's canonical headless T3 service, the intended shape is a user systemd unit with linger enabled:

```ini
[Unit]
Description=T3 Code headless server
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
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

[Install]
WantedBy=default.target
```

Verify linger:

```bash
loginctl show-user semyon -p Linger -p State
```

## Restart on update pattern

Use a `.path` watcher plus oneshot restart service.

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

Enable:

```bash
systemctl --user daemon-reload
systemctl --user enable t3-code-headless.service
systemctl --user enable --now t3-code-headless-update.path
```

## Stabilization sequence

When the desktop SSH launcher is flapping but systemd should be canonical:

1. Identify and stop the SSH-launched T3 process using process/port checks.
2. Clear obviously stale SSH `notty` sessions from the launcher if they have accumulated, taking care not to kill real TTY sessions.
3. Start/reset the systemd user service:

```bash
systemctl --user reset-failed t3-code-headless.service || true
systemctl --user start t3-code-headless.service
```

4. Verify single owner:

```bash
systemctl --user show t3-code-headless.service -p MainPID -p NRestarts -p ActiveState -p SubState --no-pager
ss -ltnp '( sport = :3773 or sport = :3774 )'
curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' -m 5 http://127.0.0.1:3773/
curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' -m 5 http://10.0.0.5:3773/
```

5. Watch for 30–60 seconds:

```bash
sleep 60
systemctl --user show t3-code-headless.service -p MainPID -p NRestarts -p ActiveState -p SubState --no-pager
pgrep -af 't3 serve|codex app-server'
ss -ltnp '( sport = :3773 or sport = :3774 )'
journalctl -u ssh --since '60 seconds ago' --no-pager | grep -c 'session opened' || true
```

## Interpretation notes

- `managed=managed` under `~/.t3-code/ssh-launch/<id>/managed` indicates the desktop/SSH launcher considers itself owner of that launch.
- A user service can be `enabled` for boot but `inactive`; that does not stabilize the current session until it is started and owns the port.
- If the desktop app keeps opening SSH sessions after systemd takes over, the server may still be healthy. The decisive checks are: one T3 listener, systemd `active`, `NRestarts=0`, HTTP 200, and no repeated `Listening on` lines from the SSH launch log.
