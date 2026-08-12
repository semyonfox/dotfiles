# Temporary server-hosted decks and local viewing

Use when Semyon asks to keep a generated deck/gallery/page hosted on the server and view it from a PC/laptop.

## Pattern

1. Copy the finished artifact directory to the server, usually under `/home/semyon/<artifact-name>/` unless it belongs in a durable stack.
2. Build on the server and serve the static output with a small user systemd service, for example:

```ini
[Unit]
Description=Temporary static artifact
After=network.target

[Service]
Type=simple
WorkingDirectory=/home/semyon/<artifact-name>
ExecStart=/usr/bin/python3 -m http.server 3037 -d dist --bind 0.0.0.0
Restart=on-failure
RestartSec=2

[Install]
WantedBy=default.target
```

3. Verify locally on the server first: `curl http://127.0.0.1:3037/`.
4. Verify from the target device, not only from the agent host. SSH to the PC/laptop and curl the LAN URL.
5. If LAN access times out while SSH/80/443 work, check firewall rules. With explicit user approval, allow the exact port, e.g. `sudo ufw allow 3037/tcp`, then re-test from the target device.
6. If firewall changes are not possible, create a local user-systemd SSH tunnel on the target device as a fallback:

```ini
ExecStart=/usr/bin/ssh -N -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 127.0.0.1:3037:127.0.0.1:3037 server
```

7. Open the final URL in the requested browser. For Semyon's PC/laptop, prefer Helium when he asks for it:

```bash
helium-browser 'http://10.0.0.5:3037/?v=cachebust'
```

## Pitfalls

- Do not assume `http://10.0.0.5:<port>` works because the service listens on `0.0.0.0`; host firewall may still block the port.
- Do not leave a local PC copy running on the same port if the user asked to monitor the server-hosted copy. Stop/disable the local service or use a cache-busted direct LAN URL so the browser is pointed at the right instance.
- After style/assets changes, use a cache-busting query string to defeat browser cache.
- Verify key static assets, not only `/`; decks can load while diagrams/CSS are stale or missing.
