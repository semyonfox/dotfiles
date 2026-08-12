# Tunnel, Postgres, and Static Nginx Hardening Notes

Use this reference when a deployed homelab Docker service is technically up but logs show noisy tunnel/database/static-site scanner errors.

## Cloudflare Tunnel QUIC/IPv6 flakiness

Symptoms:

- `cloudflared` logs contain repeated QUIC timeout noise such as `failed to dial to edge with quic`, `timeout: no recent network activity`, or intermittent resolver errors.
- The tunnel may still work, but noisy QUIC/UDP/IPv6 failures make service health look worse than it is.

Fix pattern:

```yaml
command: tunnel --no-autoupdate --protocol http2 run
```

For token-form commands:

```yaml
command: tunnel --no-autoupdate --protocol http2 run --token ${CLOUDFLARE_TUNNEL_TOKEN}
```

Verify actual protocol, not just config:

```bash
docker logs --since=5m <cloudflared-container> 2>&1 \
  | grep -E 'Initial protocol|Registered tunnel connection|ERR|WRN'
```

Expected evidence:

```text
Initial protocol http2
Registered tunnel connection ... protocol=http2
```

Caveat: recent `cloudflared` may still run an environment precheck and print `QUIC connection successful` / `suggested_protocol=quic`. That does not mean it is using QUIC. Trust the `Initial protocol` and `Registered tunnel connection ... protocol=http2` lines.

## Postgres healthcheck database-name spam

Symptom:

```text
FATAL: database "<user>" does not exist
```

Common cause: healthcheck only specifies user:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U irish_data"]
```

Postgres defaults the database name to the user name, so it tries DB `irish_data` even if the real app DB is `ireland_public`.

Fix:

```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U irish_data -d ireland_public"]
```

Apply with compose and verify:

```bash
docker compose --env-file stack.env -f stack.yaml config --quiet
docker compose --env-file stack.env -f stack.yaml up -d db
docker inspect <db-container> --format 'health={{json .Config.Healthcheck}} status={{.State.Status}} health_status={{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}'
docker logs --since=90s <db-container> 2>&1 | grep -Ei 'FATAL|database "<user>"|error|failed' || true
```

## Netdata Postgres autodiscovery login failures

Symptom after fixing healthcheck:

```text
FATAL: password authentication failed for user "netdata"
```

Netdata may autodiscover Postgres containers and attempt a default monitoring login. Options:

1. Disable/ignore that collector for the container, if Postgres metrics are not needed.
2. Create a limited monitoring user.

Minimal monitoring-user pattern:

```bash
docker exec <postgres-container> psql -U <admin-user> -d <real-db> -v ON_ERROR_STOP=1 \
  -c "CREATE ROLE netdata WITH LOGIN PASSWORD '<generated-password>'; GRANT pg_monitor TO netdata;"
```

Verify:

```bash
docker exec -e PGPASSWORD='<password>' <postgres-container> \
  psql -U netdata -d postgres -tAc 'select current_user, current_database();'
sleep 30
docker logs --since=40s <postgres-container> 2>&1 | grep -Ei 'FATAL|password authentication|error|failed' || true
```

Use a generated password in durable setups. A hardcoded/demo password is acceptable only as an emergency local fix and should be rotated if exposed.

## Static Nginx fallback returning 200 for scanner paths

Symptoms:

- Bot/scanner paths such as `/error.log`, `/logs/error.log`, `/config.js`, `/sendgrid.js`, `/.env`, etc. return HTTP `200` because Nginx falls back to `/404.html` using `try_files ... /404.html`.
- This usually does not leak real logs, but scanners see `200` and keep probing. It also pollutes logs and metrics.

Safer pattern:

```nginx
error_page 404 /404.html;

# Do not turn scanner probes for logs/config/secrets into successful SPA-style pages.
location ~* (^|/)\. { return 404; }
location ~* \.(?:log|env|ini|conf|bak|backup|old|orig|sql|sqlite|db|pem|key|crt|yml|yaml)(?:\..*)?$ { return 404; }

location / {
    try_files $uri $uri/ ${uri}.html =404;
}
```

If the site supports content negotiation or markdown variants, keep those candidates but end with `=404`, not `/404.html`:

```nginx
try_files ${uri}${md_suffix} ${uri}/index${md_suffix} $uri $uri/ ${uri}.html =404;
```

Verify syntax and external status codes:

```bash
docker run --rm -v /path/to/nginx.conf:/etc/nginx/conf.d/default.conf:ro nginx:alpine nginx -t
# After rebuild/redeploy:
curl -sS -o /tmp/body -w '%{http_code} %{content_type}\n' https://example.com/
curl -sS -o /tmp/body -w '%{http_code} %{content_type}\n' https://example.com/error.log
curl -sS -o /tmp/body -w '%{http_code} %{content_type}\n' https://example.com/.env
```

Expected: homepage `200`, scanner/missing sensitive-looking paths `404`.
