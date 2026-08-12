# Hermes dashboard auth and permanent LAN service notes

Session-derived notes for self-hosting the Hermes web dashboard on a LAN.

## Permanent LAN service

Use a user systemd service when the dashboard should survive reboot:

```ini
[Unit]
Description=Hermes dashboard
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=/home/<user>/.hermes/hermes-agent
Environment=HERMES_HOME=/home/<user>/.hermes
ExecStart=/home/<user>/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main dashboard --host 0.0.0.0 --port 9119 --no-open --skip-build
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

Notes:
- `--host 0.0.0.0` is the LAN bind.
- `--skip-build` is useful once the web UI has already been built.
- `systemctl --user enable --now hermes-dashboard.service` makes it persistent.
- User lingering must be enabled for reboot survival (`loginctl show-user <user> -p Linger`).

## Basic auth login flow

When basic auth is enabled, verify the dashboard is advertising the provider:

```bash
curl -s http://127.0.0.1:9119/api/status | jq '.auth_required, .auth_providers'
```

Expected shape:
- `auth_required: true`
- `auth_providers` contains `basic`

Important endpoint detail:
- The credential form posts to `/auth/password-login`
- Do not use `/api/auth/password-login`

A successful password login returns JSON like:

```json
{"ok": true, "next": "/"}
```

## Basic auth config surface

The provider reads from `dashboard.basic_auth` in `~/.hermes/config.yaml`.
Useful keys:
- `username`
- `password_hash` (preferred)
- `password` (plaintext fallback)
- `secret`
- `session_ttl_seconds`

## Common failure modes

- Login seems broken immediately after changing the password: restart the dashboard service so it reloads config.
- Browser still shows an old failure: clear dashboard cookies and retry.
- A 401 from `/api/auth/password-login` usually means the wrong endpoint was used.
- `dashboard.basic_auth` with no password or hash configured means the provider will not register.
