# R2, Queues, and Email Routing account migration notes

Use when moving a Cloudflare-backed app between accounts after the DNS zone has already moved.

## R2 migration safest path

- Do **not** rely on `wrangler r2 object get/put` alone for cross-account backups during auth changes. Wrangler commands target the currently-authenticated account, and `r2 object get/put` defaults to local storage unless `--remote` is supplied.
- Prefer using existing R2 S3 credentials for the source account to create a local backup before changing Wrangler auth. Verify:
  - object count from manifest/listing;
  - total bytes;
  - local file count under the backup root.
- After logging Wrangler into the destination account, create/enable the destination R2 bucket and upload from the verified local backup.
- If the destination account returns `Please enable R2 through the Cloudflare Dashboard. [code: 10042]`, R2 has not been enabled for that account yet. Have the user enable R2 once in Dashboard, then retry bucket creation.
- Do not switch runtime `STORAGE_ENDPOINT`, access keys, or bucket settings until destination upload is complete and spot-verified.

## Queue migration

- Recreate queue names in the destination account and capture new queue IDs.
- For HTTP pull consumers, recreate consumer settings explicitly: batch size, retries, visibility timeout, retry delay, dead-letter queue if any.
- Do not switch app env vars until all queues exist and consumers are visible in `wrangler queues list` / `wrangler queues consumer http list`.

## Wrangler auth pitfall

If a background migration job shells out to Wrangler, and Wrangler login is changed mid-run, later object operations may silently target the new account. Kill stale jobs before switching auth, or use account-stable API credentials (S3 for R2, API token with account ID) inside the job.

## Email Routing cutover

- Cloudflare Email Routing can have a verified destination and catch-all rule prepared before MX cutover.
- Enabling Email Routing fails with `Non-Cloudflare MX records exist [code: 2008]` until old MX records are removed/replaced.
- Provide the user with an email-only zone/import file or exact records; do **not** tell them to replace the whole zone file. The file should clearly say to delete old MX, add Cloudflare MX/SPF/DKIM, and keep app DNS records.
- OAuth Wrangler login may manage Email Routing but still fail raw DNS record APIs. For CLI DNS changes, require a token with `Zone:DNS:Edit`, or have the user edit DNS in Dashboard.
