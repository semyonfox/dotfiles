# Immich machine-learning unhealthy healthcheck triage

Use when `immich_machine_learning` is running but Docker marks it `unhealthy`.

Observed pattern:

- Container status: `Up ... (unhealthy)` for `ghcr.io/immich-app/immich-machine-learning:*cuda`.
- Healthcheck: `python3 healthcheck.py` exits `1` with empty output.
- `healthcheck.py` probes `http://localhost:3003/ping`.
- Manual probe inside container can time out waiting for `/ping` even though gunicorn is listening.
- Logs may show only gunicorn startup/control socket lines and no obvious error.

Safe triage:

```bash
docker ps --filter name=immich_machine_learning --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
docker inspect immich_machine_learning --format '{{json .State.Health}}'
docker logs --tail=120 immich_machine_learning
docker exec immich_machine_learning python3 -c "import requests; r=requests.get('http://127.0.0.1:3003/ping', timeout=5); print(r.status_code, r.text[:100])"
```

If the container is merely wedged, restart only the ML service/container rather than recreating the stack:

```bash
cd /home/semyon/server-stacks/immich
docker compose -f stack.yaml restart immich-machine-learning
sleep 30
docker ps --filter name=immich --format 'table {{.Names}}\t{{.Status}}'
docker exec immich_machine_learning python3 -c "import requests; r=requests.get('http://127.0.0.1:3003/ping', timeout=5); print(r.status_code, r.text[:100])"
```

Verification target:

- `immich_machine_learning` becomes `healthy`.
- `/ping` returns `200 pong`.
- Other Immich containers remain healthy/running.
- Confirm the live incident is clear with `docker ps --filter health=unhealthy`. Assess exited containers separately: an old ad-hoc or Compose E2E/test container with `restart=no` is historical state, not a production-health failure. Inspect Compose labels, finish time, and restart policy before deciding to start or remove it.

Important caution:

The Immich stack is often managed with Portainer/env-file style variables. Running `docker compose` directly may print warnings like `TUNNEL_TOKEN variable is not set` or DB vars defaulting blank. For a simple ML healthcheck wedge, use `restart` only; do not `up -d` or recreate containers unless env handling is deliberately checked first.
