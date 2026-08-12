# Home Assistant Container in server-stacks

Session-derived reference for adding Home Assistant to Semyon's homelab stack repo.

## Desired layout

```text
/home/semyon/server-stacks/homeassistant/
├── README.md
└── stack.yaml

/home/semyon/server-stacks/data/homeassistant/config/
└── Home Assistant generated config, DBs, logs, secrets, .storage
```

The runtime data path is intentionally under `server-stacks/data/` so generated YAML, SQLite DBs, tokens, logs, and `.storage` stay out of git. `data/` is ignored by the repo `.gitignore`.

## Compose pattern

```yaml
name: homeassistant

services:
  homeassistant:
    container_name: homeassistant
    image: ghcr.io/home-assistant/home-assistant:stable
    restart: unless-stopped
    network_mode: host
    privileged: true
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      TZ: Europe/Dublin
    volumes:
      - ../data/homeassistant/config:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
```

## Verification pattern

From `/home/semyon/server-stacks/homeassistant`:

```bash
docker compose -f stack.yaml config
docker compose -f stack.yaml up -d
docker ps --filter name=homeassistant --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
curl -s -o /tmp/ha_root.html -w 'HTTP %{http_code}\n' http://127.0.0.1:8123/
git check-ignore -v ../data/homeassistant/config/.HA_VERSION ../data/homeassistant/config/configuration.yaml
```

A `302` from `/` is a valid sign that the Home Assistant UI is responding.

## Notes

- LAN URL observed in the session: `http://10.0.0.5:8123/`.
- Host networking is deliberate for LAN discovery and local integrations.
- Bluetooth may still log permissions warnings even with `privileged`, `NET_ADMIN`, `NET_RAW`, and DBus mounted. Treat as non-fatal unless BLE devices are actually required.
- This is Home Assistant Container, not HAOS/Supervised. Add-ons are not available; run add-on-like services as separate Docker stacks.

## User correction captured

The first attempt placed files under `/home/semyon/homeassistant`. Semyon corrected this: new server services should be added under `/home/semyon/server-stacks/<stack>/` and structured like the other stacks. Future agents should inspect and follow repo conventions before creating service directories.
