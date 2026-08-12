# Oghma live deployment/provider audit

Use when Semyon asks how Oghma/OghmaNotes is currently deployed, what is self-hosted, or how the homelab setup maps back to old AWS/Cloudflare equivalents.

## Current-truth workflow

1. **Inspect the live server first** rather than trusting repo docs:
   ```bash
   ssh server 'docker compose ls; docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" | egrep -i "oghma|postgres|redis|qdrant|cloudflared|nginx|rustfs"'
   ssh server 'cd /home/semyon/server-stacks/oghma && docker compose --env-file stack.env -f stack.yaml config --services'
   ```
2. **Read stack config with secret redaction**:
   - `/home/semyon/server-stacks/oghma/stack.yaml`
   - `/home/semyon/server-stacks/oghma/nginx/nginx.conf`
   - `/home/semyon/server-stacks/oghma/.env.prod`, `.env.dev`, `stack.env` — redact values, keep names/provider hints.
   - `/home/semyon/jenkins/env/oghma-prod.env` and `oghma-dev.env` if checking deployed Jenkins envs.
3. **Inspect live container env/provider settings**, not just compose files:
   ```bash
   for c in oghma-prod oghma-prod-worker oghma-dev oghma-dev-worker; do
     ssh server "docker exec $c /bin/sh -lc 'env | sort | egrep \"^(QUEUE_PROVIDER|REDIS_HOST|QDRANT_URL|QDRANT_COLLECTION|STORAGE_ENDPOINT|STORAGE_BUCKET|STORAGE_REGION|STORAGE_PATH_STYLE|STORAGE_PREFIX|CLOUDFLARE_ACCOUNT_ID|EMAIL_FROM|CLOUDFLARE_EMAIL_FROM|SES_|SQS_|NEXT_PUBLIC_CHAT_URL|MARKER_|LLM_API_URL|EMBEDDING_API_URL|RERANK_API_URL)=\"'"
   done
   ```
   Redact tokens/keys/secrets. Provider endpoints and bucket names are usually safe/useful.
4. **Verify public and internal health**:
   ```bash
   ssh server 'curl -fsS http://192.168.48.30:3000/api/health; curl -fsS http://192.168.48.40:3000/api/health'
   ssh server 'curl -sSI https://oghmanotes.ie | sed -n "1,15p"; curl -sSI https://dev.oghmanotes.ie | sed -n "1,15p"'
   ```
5. **Reconstruct historical provider mapping from Git history without switching branches**:
   - Current docs: `infra/HOMELAB.md`, `infra/AWS_INFRASTRUCTURE.md`, `infra/MIGRATION_RUNBOOK.md`, `infra/TARGET_HOSTING.md`, repo `AGENTS.md`.
   - Useful history search:
     ```bash
     git log --all --date=short --pretty='%h %ad %s' -- infra docs .github Jenkinsfile package.json src/lib src/app/api \
       | egrep -i 'homelab|aws|amplify|cloudflare|lambda|sqs|rds|redis|bullmq|s3|rustfs|jenkins|migration|route 53|ses|email'
     ```
   - Inspect old files with `git show <commit>:<path>`, especially pre-homelab commits around `19f9182b^`, `2d2678d1^`, `517f59e5^` if still present.

## Known Oghma deployment shape observed 2026-07

- Public URLs verified through Cloudflare: `https://oghmanotes.ie`, `https://dev.oghmanotes.ie`.
- Homelab compute path: Cloudflare Tunnel → `oghma-nginx` → `oghma-prod`/`oghma-dev` Next.js containers.
- Persistent/stateful local services: `oghma-postgres` (pgvector/Postgres 18), `oghma-redis` (BullMQ/cache/rate-limit), `oghma-qdrant` (vector store), plus Jenkins-managed app/worker images.
- `oghma-qdrant` may be **Jenkins-created rather than compose-managed**. Check `Jenkinsfile` vector-store stage before assuming every live Oghma container is in `stack.yaml`.
- `oghma-rustfs` may still be running even when live app env points storage at Cloudflare R2. Always compare `STORAGE_ENDPOINT` from live containers before saying storage is self-hosted.
- Live queue provider can be BullMQ even when Cloudflare Queues env names exist. `QUEUE_PROVIDER=bullmq` + `REDIS_HOST=oghma-redis` means Redis/BullMQ is the active queue path.
- Chat Lambda was retired when moving off Amplify: `NEXT_PUBLIC_CHAT_URL` empty and chat streaming handled by `/api/chat` in the long-running Next.js app.

## Historical mapping to report

| Old AWS service | Homelab/current equivalent |
|---|---|
| Amplify Web Compute | Jenkins-built Docker app containers on homelab |
| Amplify/SSR timeout workaround chat Lambda | Direct `/api/chat` SSE in the Next.js app |
| RDS Postgres | `oghma-postgres` pgvector/Postgres container |
| SQS + ECS/Fargate worker | Redis + BullMQ + `oghma-{env}-worker` containers |
| S3 | Check live env: historically S3, often now R2; RustFS may be present as local S3-compatible storage/fallback |
| ElastiCache/Valkey | `oghma-redis` |
| Secrets Manager | Jenkins env files on server |
| ECR/GitHub Actions worker deploy | Local Docker images built/deployed by Jenkins |
| NAT/VPC plumbing | Not needed on homelab behind Cloudflare Tunnel |

## Pitfalls

- Do not describe the stack as “all self-hosted” until you have checked live `STORAGE_ENDPOINT`, LLM/embed/rerank endpoints, email provider, and Cloudflare tunnel/DNS usage. Compute can be self-hosted while storage/email/AI are external.
- Current docs may lag live env. Treat `infra/HOMELAB.md` as a guide, not proof, when live containers disagree.
- Email provider migrations can leave stale env names. If code expects `CLOUDFLARE_EMAIL_API_TOKEN`/`EMAIL_FROM` but live env only has `SES_*`, report a likely transactional-email config mismatch rather than assuming SES still works.
- Do not send test emails or enqueue jobs just to verify provider config unless Semyon explicitly approves the side effect.
