# Temporary localhost gallery via SSH reverse tunnel + Helium

Use when Semyon asks to view a generated local gallery/page from his PC/laptop and says something like “ssh the port to my PC” or “open it in Helium.”

## Pattern

This is for artifacts served only on the agent/server localhost, e.g. `python3 -m http.server 8766 --bind 127.0.0.1`, where the PC should see the same page at its own `127.0.0.1:<port>`.

1. Verify the local gallery server first:

```bash
curl -fsS http://127.0.0.1:<port>/ | head
```

2. Probe the target PC and Helium path:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 pc \
  'hostname; command -v helium-browser || command -v helium || command -v /opt/helium-browser-bin/helium || true; id -u; ls -1 /run/user/1000/hypr 2>/dev/null | head -1 || true'
```

3. Ensure the port is free on the PC:

```bash
ssh pc 'ss -ltn sport = :<port> || true'
```

4. Create a reverse SSH tunnel from the agent/server to the PC:

```bash
env -u NPM_CONFIG_PREFIX ssh -T -N \
  -o ExitOnForwardFailure=yes \
  -o ServerAliveInterval=30 \
  -o ServerAliveCountMax=3 \
  -R 127.0.0.1:<port>:127.0.0.1:<port> pc
```

Run it as a tracked background process so it can be killed later. This exposes the agent/server’s local page as `http://127.0.0.1:<port>/` on the PC without touching UFW or binding the gallery publicly.

5. Verify from the PC:

```bash
ssh pc 'curl -fsS http://127.0.0.1:<port>/ | grep -o "<expected page title>" | head -1'
```

6. Open in Helium in the live Hyprland session:

```bash
ssh pc '
  export XDG_RUNTIME_DIR=/run/user/1000
  export HYPRLAND_INSTANCE_SIGNATURE=$(ls -1 /run/user/1000/hypr | head -n1)
  hyprctl dispatch dpms on >/dev/null 2>&1 || true
  systemd-run --user --collect \
    --setenv=XDG_RUNTIME_DIR=/run/user/1000 \
    --setenv=WAYLAND_DISPLAY=wayland-1 \
    --setenv=HYPRLAND_INSTANCE_SIGNATURE="$HYPRLAND_INSTANCE_SIGNATURE" \
    /usr/bin/helium-browser "http://127.0.0.1:<port>/?v=$(date +%s)"
'
```

7. Verify Helium is running and the tunnel still lives:

```bash
ssh pc 'pgrep -af helium | head -5'
```

## Pitfalls

- If the local gallery server died, restart it before creating the tunnel; otherwise the tunnel can be healthy while the browser shows connection failure.
- Use `-R 127.0.0.1:PCPORT:127.0.0.1:SERVERPORT pc` for “make it available on the PC’s localhost.” Use `-L` only when pulling a remote server page down to the current machine.
- Prefer a localhost tunnel over opening firewall ports for short-lived private galleries.
- Add a cache-busting query string when reopening generated galleries in Helium.
- Keep the tunnel as a tracked background process and report its process/session ID so it can be stopped cleanly.
- Run the tunnel with `env -u NPM_CONFIG_PREFIX ssh -T -N ...` on Semyon's machines. His shell can leak `NPM_CONFIG_PREFIX=/home/semyon/.local`, which makes nvm print warnings into SSH sessions; `-T` also avoids unnecessary TTY/session noise for tunnel-only commands.
- If the tunnel dies with `Connection to 10.0.0.15 closed by remote host`, first verify PC reachability with `ssh -T -o BatchMode=yes -o ConnectTimeout=5 pc 'hostname'` and `ping`. Do not keep retrying if the host is offline or returns `No route to host`; wait for PC/LAN to come back, then recreate the tunnel.
