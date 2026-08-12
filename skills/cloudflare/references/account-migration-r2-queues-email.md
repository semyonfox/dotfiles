# Cloudflare account migration: R2, Queues, and Email Routing pitfalls

Use this when a domain has already been moved between Cloudflare accounts but app-adjacent resources are still stranded in the old account.

## Safe sequence

1. Verify which account Wrangler/API is currently authenticated against (`wrangler whoami --json`) and record source/destination account IDs.
2. Inspect the destination zone status and public DNS before changing anything.
3. Back up old-account storage before switching env vars or deleting resources.
4. Recreate account-scoped resources in the destination account:
   - Queues: names, IDs, and HTTP pull consumers/settings.
   - R2: bucket plus object data; requires R2 to be enabled on the destination account first.
5. Update runtime env only after the destination resources exist and are verified.
6. Keep old resources until the app is verified against destination resources.

## R2 migration notes

- R2 is account-scoped; moving a zone does not move buckets.
- If the destination account returns `Please enable R2 through the Cloudflare Dashboard. [code: 10042]`, bucket creation/upload cannot proceed until R2 is enabled in the dashboard.
- Wrangler `r2 object get` defaults to local storage unless `--remote` is passed. For remote backups, always use `--remote` or use the S3-compatible API with existing R2 S3 credentials.
- For bulk backup/copy, the S3-compatible API is often faster and less fragile than one `wrangler r2 object get` process per object. Verify:
  - manifest count,
  - total byte count,
  - local file count under the object root,
  - spot-check object sizes/hashes if needed.

## Queues migration notes

- Queues are account-scoped; moving DNS/zone does not move queues.
- Recreate HTTP pull consumers explicitly; creating a queue alone leaves `consumers=0`.
- Preserve key settings where applicable: batch size, max retries, visibility timeout, retry delay.
- Queue IDs change in the destination account; update app/env configuration after creation.

## Email Routing migration notes

- A catch-all forwarding rule can exist while Email Routing is still disabled/unconfigured. Check both rules and settings.
- Cloudflare Email Routing will not enable while non-Cloudflare MX records exist (`Non-Cloudflare MX records exist [code: 2008]`).
- Replacing Google Workspace MX with Cloudflare Routing is an inbound cutover. Historical mailbox data is not migrated, and outbound “send as” still needs Workspace, SMTP, or another sending provider.
- Wrangler OAuth scopes may include `zone:read` and `email_routing:write` but still lack raw DNS-record edit permission. If DNS record listing/editing returns API authentication errors, use the dashboard or a user API token with `Zone:DNS:Edit` for the destination zone.

## Verification checklist

- Destination account has active zone and expected nameservers.
- Public app hosts still return healthy HTTP responses.
- Destination queues exist with consumers.
- Destination R2 bucket exists and object counts/bytes match the source backup.
- Runtime env points at destination account IDs/endpoints/queue IDs.
- Public MX points at the intended mail provider, and Email Routing settings show enabled/configured if using Cloudflare.
