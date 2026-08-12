# OghmaNotes Cloudflare account migration lessons (2026-07-01)

Session-specific lessons from moving `oghmanotes.ie` resources from a company Cloudflare account back to Semyon's personal account.

## R2 migration pitfalls

- `wrangler r2 object get/put` can default to local storage unless `--remote` is passed. For real account migration, always include `--remote` when using Wrangler object commands.
- Long-running Wrangler-based R2 jobs inherit the current Wrangler account context. If `wrangler login` is switched mid-job, the process may start targeting the new account and fail or write to the wrong place. Stop/restart jobs after an auth switch.
- R2 may need to be enabled in the destination account via Dashboard before `wrangler r2 bucket create` works. Error shape: `Please enable R2 through the Cloudflare Dashboard. [code: 10042]`.
- For bulk R2 backup/restore, S3-compatible credentials with `@aws-sdk/client-s3` are faster and less brittle than spawning one Wrangler process per object. Verify count and byte total against a manifest before switching app env.

## Email Routing cutover

- Cloudflare Email Routing can be prepared with verified destinations and catch-all forwarding before MX cutover, but `wrangler email routing enable <domain>` fails while non-Cloudflare MX records exist.
- Replace the old Google Workspace MX (`smtp.google.com`) with Cloudflare's three MX records, then enable routing and verify `Status: ready`.
- MX/TXT/DKIM/DMARC are DNS-only; never proxy mail-related records.
- When giving the user DNS records to import into Cloudflare, provide a small `.txt`/zone-file containing only email records and explicitly warn not to replace the full zone. Discord users may need this as a real file attachment, not pasted text.

## Verification checklist

1. `wrangler whoami --json` shows the expected destination account.
2. `dig +short MX <domain> @1.1.1.1` shows Cloudflare Email Routing MX records.
3. `dig +short TXT <domain>` includes the Cloudflare SPF record.
4. `dig +short TXT cf2024-1._domainkey.<domain>` returns DKIM.
5. `wrangler email routing settings <domain>` shows `Enabled: true` and `Status: ready`.
6. Public app URLs still return HTTP 200 after DNS changes.
7. R2 upload manifest count and total bytes match the source before switching runtime env.
