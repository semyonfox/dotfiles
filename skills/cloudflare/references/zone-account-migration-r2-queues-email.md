# Cloudflare account migration: R2, Queues, and Email Routing pitfalls

Use this alongside `references/zone-account-migration.md` when moving an app/domain between Cloudflare accounts and the app uses R2, Queues, or Email Routing.

## R2 migration

- Do not treat zone migration as storage migration. R2 buckets and S3 API credentials are account-scoped and must be recreated/migrated separately.
- Prefer S3-compatible API clients for bulk backup/restore when exact keys matter. `wrangler r2 object get/put` is convenient for spot checks, but can surprise you around local-vs-remote mode and key encoding.
- Always pass `--remote` to Wrangler R2 object commands when reading real Cloudflare R2. Without it, Wrangler may look at local dev storage.
- Preserve exact object keys. Keys containing percent-encoded sequences like `%2C`, `%26`, `%E2%80%93`, etc. can accidentally be decoded by some CLI paths. Verify with a manifest diff: original key set vs remote key set, object count, and total bytes. If decoded duplicates are created, upload missing exact keys via API and delete the decoded extras.
- Verify S3 credentials against a real object before switching runtime env:
  - `HeadObject` a known key.
  - `ListObjectsV2` with `MaxKeys=1`.
  - Use `forcePathStyle: true`, `region: auto`.
- The R2 endpoint must match the bucket/account. If a jurisdiction endpoint such as `https://<account>.eu.r2.cloudflarestorage.com` returns `NoSuchBucket` but the default endpoint works, use `https://<account>.r2.cloudflarestorage.com` for the app.

## Queues migration

- Queue IDs are account-scoped. Recreate queues in the destination account and update every env file that carries queue IDs.
- For HTTP pull consumers, recreate the HTTP pull consumer settings too: batch size, retries, visibility timeout, retry delay.
- A token that can list queues is not sufficient proof it can consume messages. Verify the exact runtime endpoint:
  - `POST /accounts/{account_id}/queues/{queue_id}/messages/pull`
- Cloudflare HTTP pull consumers need an API token with `Account → Queues → Edit` on the destination account. If pull returns `401 Authentication error` while queue listing works, regenerate the token with Queues Edit, not just broad/read/list permissions.
- Emergency workaround when a proper custom token cannot be generated immediately: Wrangler's OAuth access token may already include `queues:write` and can authenticate HTTP pull endpoints. Read it from the active Wrangler profile only after verifying scope/expiry, patch runtime envs, and install a refresh shim that runs `wrangler whoami` before copying the refreshed OAuth token back into env files. This is a bridge, not the preferred steady-state; note the expiry and verify worker logs after container recreation.

## Email Routing cutover

- Replacing Google Workspace mail with Cloudflare Email Routing requires replacing the Google MX records with Cloudflare's MX records; do not leave the zone with no MX.
- Email-related records are DNS-only / no proxy: MX, SPF TXT, DKIM TXT, DMARC TXT.
- After DNS records are present, run/verify Email Routing enablement and settings; the catch-all forwarding rule existing is not enough if Email Routing status is still `unconfigured`.
- Keep useful non-mail TXT records such as Google site verification unless there is a reason to remove them.

## Runtime cutover checklist

1. Back up old R2 to local storage with a manifest.
2. Recreate destination R2 bucket and upload all objects.
3. Diff old manifest vs destination remote: count, bytes, missing keys, extra keys.
4. Recreate destination Queues + HTTP pull consumers.
5. Generate destination R2 S3 credentials and Queues Edit API token.
6. Patch all runtime env file copies used by Jenkins/Docker, not just source-control examples.
7. Recreate/redeploy app and worker containers so new env is loaded.
8. Verify running container env, app HTTP 200s, Email Routing ready, and worker logs for queue-auth errors.
9. If using a short-lived Wrangler OAuth token as a queue-token bridge, add an hourly/daily refresh job and record its local log path; otherwise the app will silently regress when the token expires.
