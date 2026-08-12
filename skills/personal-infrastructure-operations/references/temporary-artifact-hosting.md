# Temporary deck / artifact hosting on Semyon's server

Use when Semyon wants a generated deck/gallery/demo kept online so he can monitor it from PC/laptop.

## Pattern

1. Build the static artifact locally first and verify it returns HTTP 200.
2. Copy it to the server, commonly under `/home/semyon/<artifact-name>/`, unless a canonical stack path is requested.
3. Serve the built static directory with a user-level systemd service so it survives shell exit. For quick Slidev/static decks, `python3 -m http.server <port> -d dist` is acceptable as a temporary user service.
4. Bind to `0.0.0.0` only after checking the artifact contains no secrets.
5. Verify from:
   - server localhost
   - Tailscale IP if useful
   - PC/laptop LAN path if that is what Semyon will use
6. Open the URL on the destination machine in Helium if requested.

## LAN/firewall pitfall

A service can be listening on `0.0.0.0:<port>` but still fail from the PC because UFW blocks the port. Probe from the actual client machine, not only from the agent host:

```bash
ssh pc 'curl --connect-timeout 5 -fsS -o /tmp/probe.html -w "%{http_code}\n" http://10.0.0.5:<port>/'
```

If Semyon explicitly approves sudo/firewall changes, allow the exact temporary port, e.g.:

```bash
sudo ufw allow 3037/tcp
```

Then re-probe from the PC.

## SSH tunnel fallback

If direct LAN port access is blocked and firewall changes are not available yet, keep the server-hosted artifact but create a PC-local tunnel:

```ini
[Unit]
Description=Local tunnel to server-hosted artifact
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:3037:127.0.0.1:3037 server
Restart=always
RestartSec=2

[Install]
WantedBy=default.target
```

Disable the tunnel once the real LAN port works so `127.0.0.1:<port>` does not hide whether the artifact is local or server-hosted.
