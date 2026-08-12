# T3 Code headless systemd + desktop SSH launcher triage

Use when T3 Code on Semyon's server repeatedly disconnects, respawns over SSH, or conflicts with a headless service.

## Durable layout/markers

T3 desktop SSH launch state lives under:

```text
~/.t3-code/ssh-launch/<launch-id>/
├── run-t3.sh
├── managed        # `managed` for desktop-managed launch, `external` for older external metadata
├── pid            # present for current managed launch
├── port
└── server.log
```

A current desktop-connected launch may run as a rootless/background process with parent `systemd,1`, not as a visible child of the SSH session. Check the marker files and `ss -ltnp` rather than assuming parentage from `pstree` alone.

T3 also writes current runtime metadata at:

```text
~/.t3-code/userdata/server-runtime.json
```

## Common collision pattern

If the desktop app is connected via SSH, it can launch/respawn its own loopback server, commonly like:

```text
t3 serve --host 127.0.0.1 --port 3773 --base-dir ~/.t3
```

Semyon may also have a user systemd service intended to own the headless server:

```text
~/.config/systemd/user/t3-code-headless.service
```

If both are active, symptoms include constant disconnect/reconnect, many `sshd: semyon@notty` sessions, duplicate/stale T3 listeners, SQLite `database is locked`, and failed shutdown/restart loops.

## Triage workflow

1. Identify owners and launch mode:

```bash
pgrep -af 't3 serve|codex app-server'
ss -ltnp '( sport = :3773 or sport = :3774 )'
for d in ~/.t3-code/ssh-launch/*; do echo "-- $d"; cat "$d"/{managed,pid,port} 2>/dev/null; done
systemctl --user status t3-code-headless.service --no-pager
systemctl --user is-enabled t3-code-headless.service
loginctl show-user semyon -p Linger -p State
```

2. Inspect T3 logs before changing anything:

```bash
readlink -f /proc/<t3-pid>/fd/1 /proc/<t3-pid>/fd/2
# then inspect that server.log tail/search
```

3. If the desktop SSH launcher owns the port and the intended systemd service should own it, do not start systemd on top of it. First disconnect/quit the desktop SSH launcher or stop the loopback process, then start the unit.

4. If stale T3 processes are present on old ports, stop their process trees after confirming the current marker `pid`/`port`.

5. Verify with real probes:

```bash
systemctl --user status t3-code-headless.service --no-pager
ss -ltnp '( sport = :3773 )'
curl -o /dev/null -s -w 'http=%{http_code} total=%{time_total}\n' -m 5 http://127.0.0.1:3773/
journalctl -u ssh --since '2 minutes ago' --no-pager | grep -c 'session opened'
```

## Intended startup/restart-on-update pattern

For always-on server ownership, use a user systemd service with linger enabled:

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

Enable with:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless.service
```

For restart-on-T3-update, add a user path unit watching the CLI/symlink and global package entrypoint:

```ini
# ~/.config/systemd/user/t3-code-headless-restart.service
[Unit]
Description=Restart T3 Code headless server after binary update

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl --user try-restart t3-code-headless.service
```

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

Then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now t3-code-headless-update.path
```

## Pitfalls

- Do not treat `~/.t3-code/ssh-launch/*/managed` as a simple `.enable`; it is desktop SSH launcher state. `managed` means the desktop app may recreate that server while connected.
- Do not start `t3-code-headless.service` while the desktop SSH launcher already owns port 3773. Resolve ownership first.
- Put `StartLimitIntervalSec=0` in `[Unit]`, not `[Service]`, for systemd user units.
- If the T3 process was launched by the desktop app with `--base-dir ~/.t3`, it may not match the headless service's intended `T3CODE_HOME=~/.t3-code`. Avoid mixing both modes unless deliberately debugging.
- Invalid user keybindings in `~/.t3-code/userdata/keybindings.json` can produce startup/schema noise; remove entries whose commands are not in T3's accepted command list.
