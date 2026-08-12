# Docker base-image bakeoff for Node static frontends

Use this when deciding between Alpine and Debian slim/Bookworm instead of treating image size as the sole metric.

## Decision model

Separate the **builder** from the **runtime**:

- Node builder: prefer `node:<LTS>-bookworm-slim` when packages may contain native dependencies. Glibc-prebuilt modules are generally the safer default.
- Static runtime: `nginx:alpine` can be a deliberate exception after the project builds and serves correctly. The final nginx base, not the discarded Node builder, dominates the final image size.
- Server/runtime images that execute Node/Python dependencies should remain Debian slim unless Alpine was explicitly built and exercised with the real dependency chain.

A high-value hybrid for a pure Vite/static application is:

```dockerfile
FROM node:22-bookworm-slim AS build
# copy lockfiles, install, then build

FROM nginx:alpine
COPY --from=build /app/dist/ /usr/share/nginx/html/
```

Use a Debian nginx runtime only when its compatibility/security requirements outweigh a materially larger image.

## Reproducible bakeoff protocol

1. Use a temporary Dockerfile, never mutate the project Dockerfile merely to benchmark variants.
2. Keep the exact source context, lockfile and build command fixed; parameterize only `NODE_IMAGE` and `NGINX_IMAGE` with global `ARG`s declared before every `FROM` that needs them.
3. Compare at least:
   - Node Alpine → nginx Alpine
   - Node Bookworm slim → nginx Alpine
   - Node Bookworm slim → nginx Bookworm
   - optional next Node LTS → same nginx runtime
4. Build each with `--no-cache` for an indicative cold build. Treat network/base-pull effects as noise; do not declare a winner from a single build-time sample.
5. Record final `docker image inspect ... .Size` and perform an actual published-port smoke test:

```bash
cid=$(docker run -d --rm -p 127.0.0.1::80 "$image")
port=$(docker port "$cid" 80/tcp | sed -E 's/.*:([0-9]+)$/\1/')
curl -fsS "http://127.0.0.1:${port}/" >/dev/null
docker rm -f "$cid"
```

6. Remove only temporary image tags, logs and Dockerfiles created for the bakeoff.

## Interpretation

- For static sites, Alpine nginx usually provides the biggest concrete size win, while a Bookworm builder preserves dependency compatibility.
- Startup differences measured in milliseconds should not drive the decision alone; validate application output and dependency behavior.
- A newer Node image may appear slower in one cold build because of image/cache/network state. Upgrade versions for supported-runtime/security reasons and project compatibility, not a single timing sample.
