# Jenkins deployment audit pattern

Use this when Semyon asks for current Jenkins deployment status, whether deploys are broken, or whether runtime containers/logs show errors.

## Scope

Jenkins success is not the same as live service health. Check both:

1. Jenkins controller and tunnel containers.
2. Jenkins job API status, queue, last build, and last failed build.
3. Last build console logs with a filtered error scan.
4. Runtime Docker containers created by the Jenkins jobs.
5. Runtime app/container logs, separating real current failures from scanner noise and expected test/build text.

## Jenkins API probe

Load the Jenkins stack env without printing secrets, then query the local Jenkins API from inside the Jenkins container:

```bash
cd /home/semyon/server-stacks/jenkins
set -a; . ./stack.env; set +a

docker exec -e U="$JENKINS_ADMIN_USER" -e P="$JENKINS_ADMIN_PASSWORD" jenkins-jenkins-1 bash -lc '
  curl -g -fsS -u "$U:$P" \
    "http://localhost:8080/api/json?tree=jobs[name,color,lastBuild[number,result,building,timestamp,duration],lastSuccessfulBuild[number],lastFailedBuild[number],buildable,inQueue]" \
  | jq -r ".jobs[] | [.name,.color,(.buildable|tostring),(.inQueue|tostring),(.lastBuild.number//\"none\"),(.lastBuild.result//if .lastBuild.building then \"BUILDING\" else \"none\" end),((.lastBuild.timestamp//0)/1000|todate),((.lastBuild.duration//0)/1000|tostring),(.lastSuccessfulBuild.number//\"none\"),(.lastFailedBuild.number//\"none\")] | @tsv"
'
```

Notes:

- `curl -g` is required because Jenkins `tree=jobs[...]` contains square brackets that curl otherwise treats as URL ranges.
- Prefer Jenkins API over parsing `/var/jenkins_home/jobs/*`; the filesystem layout can include symlinks and Jenkins-specific metadata.
- Do not print `stack.env` or credentials.

## Console log scan

For each job, scan the last build console for suspicious text, but treat results as leads, not proof:

```bash
for job in artificial irish-rail-nabber oghma-dev oghma-prod portfolio swim swim-dev swim-observability; do
  echo "### $job"
  docker exec -e U="$JENKINS_ADMIN_USER" -e P="$JENKINS_ADMIN_PASSWORD" jenkins-jenkins-1 bash -lc \
    "curl -g -fsS -u \"\$U:\$P\" 'http://localhost:8080/job/$job/lastBuild/consoleText' 2>/dev/null \
      | grep -Ei '(^ERROR:|ERROR|FAILURE|FAILED|Exception|Traceback|fatal:|Cannot|denied|unhealthy|exited)' \
      | tail -12 || true"
done
```

Common false positives seen in this environment:

- Rust/Node packages containing `error`, e.g. `thiserror`, `serde_path_to_error`.
- Test fixtures intentionally logging `ErrorBoundary`, `Test Error Message`, or debug handler output.
- Build artefact paths like `AuthErrorPage` or `/auth/error`.
- Compose/network messages such as `network ... already exists` when the build still ends SUCCESS.

## Runtime container checks

After Jenkins status, check live containers and logs:

```bash
docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' \
  | grep -Ei 'NAMES|artificial|irish|portfolio|swim|uisce|oghma|loki|grafana|promtail'

for c in $(docker ps -a --format '{{.Names}}' | grep -Ei 'artificial|irish|portfolio|swim|uisce|oghma|loki|grafana|promtail' | sort); do
  echo "### $c"
  docker logs --since=24h "$c" 2>&1 \
    | grep -Ei 'error|exception|traceback|fatal|panic|failed|unhealthy|denied|ECONNREFUSED|Invalid login|timeout|segfault' \
    | tail -25 || true
done
```

Interpretation patterns:

- Cloudflared QUIC/DNS timeout bursts can be transient if containers remain up and public probes pass.
- Promtail `could not inspect container info: No such container` often appears after Jenkins recreates containers; check if it continues constantly before treating it as failure.
- Nginx missing-file errors from scanner probes (`/config.js`, `/sendgrid.js`, etc.) are not app crashes, but a `200` on log-looking paths such as `/error.log` should trigger a quick exposure check.
- For DB containers, repeated `FATAL` logs can come from a healthcheck using the wrong default database even when app DB connections are healthy.

## Known local pitfall: Irish Rail DB healthcheck

If `irish_rail_db` logs repeat:

```text
FATAL: database "irish_data" does not exist
```

Check the healthcheck. A probe like:

```bash
pg_isready -U irish_data
```

makes Postgres try database `irish_data`. The app database is `ireland_public`, so the healthcheck should use:

```bash
pg_isready -U irish_data -d ireland_public
```

This is log spam/config hygiene rather than proof the API/daemon are down; verify the API/daemon containers and their `DATABASE_URL` separately.
