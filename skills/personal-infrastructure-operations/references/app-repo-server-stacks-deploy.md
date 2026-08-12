# App Repo + Server-Stacks Deployment Pattern

Use when a live homelab service is built from an application repository but deployed via `/home/semyon/server-stacks/<stack>/stack.yaml`.

## Pattern

Some services have two sources of truth that both matter:

- App repo: source code, Dockerfile, application Compose for local/dev, package locks, frontend/backend code.
- `server-stacks` repo: live Compose/Portainer/Jenkins deployment config, env-file references, image names, volumes, tunnel commands.

If a fix changes both runtime code and live deployment shape, commit and push both repos separately.

## Safe workflow

1. Inspect app repo status and `server-stacks` status separately.
2. Make or preserve app changes in the app repo.
3. Mirror only deployment-relevant Compose changes into `/home/semyon/server-stacks/<stack>/stack.yaml` and the tracked `~/code/personal/server-stacks/<stack>/stack.yaml` copy if that repo exists separately.
4. Validate Compose with the real live env file where needed:

```bash
docker compose --env-file /home/semyon/server-stacks/<stack>/stack.env -f stack.yaml config --quiet
```

5. Build or deploy locally if appropriate, then probe live URLs/container logs.
6. Before committing, stage exact files only. Do not `git add .` in `server-stacks`; local `.env`, backup env files, and generated runtime files may be present.
7. Push the app repo first if Jenkins is triggered from app code.
8. Push `server-stacks` only for tracked deployment config changes.
9. If Jenkins starts after the push, wait for the job to finish, inspect the console tail, then re-run live verification. The Jenkins redeploy can replace containers and undo manual verification assumptions.

## Verification examples

```bash
# Jenkins job state via API, then console tail if needed
curl -fsS -u "$JENKINS_USER:$JENKINS_TOKEN" \
  'http://localhost:8080/job/<job>/lastBuild/api/json?tree=number,result,building,duration'

# Runtime shape after Jenkins redeploy
docker inspect <container> --format '{{range .Config.Env}}{{println .}}{{end}}'
docker inspect <container> --format '{{range .Mounts}}{{println .Destination .Type .Name}}{{end}}'
docker logs --since=2m <container>
curl -sS -o /tmp/probe -w 'http=%{http_code} size=%{size_download}\n' https://example.com/
```

## Pitfalls

- A manual `docker compose up -d` can be correct but temporary if Jenkins later redeploys from a different tracked stack file.
- A persistent SQLite path such as `DB_PATH=/data/app.db` needs both an app setting and a live Compose volume; otherwise it may silently write inside the container filesystem.
- `server-stacks` working trees often contain untracked `.env` and backup files. Treat those as dangerous by default and leave them unstaged unless the user explicitly asks.
