# Oghma runtime auth/email diagnostics

Use this when OghmaNotes auth, OAuth, email verification/reset, or queue/worker behaviour breaks after a Jenkins deploy or env change.

## Deployment shape

Oghma has two classes of containers:

- Persistent stack services live under `/home/semyon/server-stacks/oghma/` and are managed by `stack.yaml`: Postgres, Redis, RustFS, nginx, Cloudflare tunnels.
- App and worker containers are recreated directly by Jenkins jobs, not normally by `oghma/stack.yaml` during deploy:
  - `oghma-prod`, `oghma-prod-worker`
  - `oghma-dev`, `oghma-dev-worker`

Runtime env for the deployed app/worker comes from:

```text
/home/semyon/server-stacks/jenkins/env/oghma-prod.env
/home/semyon/server-stacks/jenkins/env/oghma-dev.env
```

The copies at `/home/semyon/server-stacks/oghma/.env.prod` and `.env.dev` may exist for stack/local parity, but patching only those does **not** update Jenkins-recreated app/worker containers.

## Investigation checklist

1. Confirm container state and source of truth:
   - `docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}' | grep -E 'oghma|NAMES'`
   - inspect env on running app/worker containers, redacting secrets.
2. Compare Jenkins env files for dev/prod auth/email vars:
   - `GOOGLE_ID`, `GOOGLE_SECRET`, `GITHUB_ID`, `GITHUB_SECRET`
   - `NEXTAUTH_URL`, `NEXT_PUBLIC_APP_URL`
   - `SES_REGION`, `SES_ACCESS_KEY_ID`, `SES_SECRET_ACCESS_KEY`, `SES_FROM_EMAIL`
   - `REDIS_HOST`, `REDIS_PORT`
3. Read recent logs before changing anything:
   - OAuth/Auth.js: `UnknownAction`, `MissingCSRF`, callback/provider errors.
   - Email: `Invalid login: 535 Authentication Credentials Invalid`.
   - Redis/queue: `ECONNREFUSED ::1:6379` or `127.0.0.1:6379` means the running container likely lacks `REDIS_HOST=oghma-redis`.

## Durable gotchas

### One OAuth app across prod/dev

For Google/GitHub OAuth, one app can cover both environments only if provider-side allowed callback/redirect URLs include both production and dev callback URLs. The local env must use the same intended client ID/secret in both prod and dev if Semyon expects one OAuth set to cover both.

A one-character mismatch in `GOOGLE_ID` between `oghma-dev.env` and `oghma-prod.env` is enough to break one environment while making the other look fine.

### AWS SES SMTP password is not the IAM secret

Oghma email code uses nodemailer SMTP against:

```text
email-smtp.${SES_REGION}.amazonaws.com:587
```

For SMTP auth, `SES_SECRET_ACCESS_KEY` must be the **SES SMTP password derived from the IAM secret**, not the raw AWS IAM secret. Raw IAM secrets produce:

```text
Invalid login: 535 Authentication Credentials Invalid
```

Minimal verification without sending mail:

```bash
python3 - <<'PY'
import pathlib, smtplib, ssl
for name, path in [('dev','/home/semyon/server-stacks/jenkins/env/oghma-dev.env'), ('prod','/home/semyon/server-stacks/jenkins/env/oghma-prod.env')]:
    env = {}
    for line in pathlib.Path(path).read_text().splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            k, v = line.split('=', 1)
            env[k] = v
    host = f"email-smtp.{env.get('SES_REGION', 'eu-west-1')}.amazonaws.com"
    with smtplib.SMTP(host, 587, timeout=20) as s:
        s.ehlo(); s.starttls(context=ssl.create_default_context()); s.ehlo()
        s.login(env['SES_ACCESS_KEY_ID'], env['SES_SECRET_ACCESS_KEY'])
    print(f'{name}: SMTP auth OK')
PY
```

If conversion is needed, use AWS's SES SMTP password derivation algorithm and avoid printing the resulting secret in chat or logs.

## Applying runtime env fixes

After changing Jenkins env files, recreate app and worker containers so they actually pick up the new env. Match the Jenkinsfile settings for container name, IP, memory, env file, network, and image tag.

Then verify:

- `docker inspect` shows expected non-secret env values on all four app/worker containers.
- App containers are healthy.
- Internal nginx probes return `200` for both hosts.
- External Cloudflare URLs return `200`.
- `/api/auth/providers` returns Google/GitHub providers for both environments.
- Fresh logs do not show `Invalid login`, `ECONNREFUSED 127.0.0.1:6379`, or new Auth.js errors.
