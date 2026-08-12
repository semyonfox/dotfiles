# Cloudflare zone account migration notes

Use when moving a domain between Cloudflare accounts, especially when Cloudflare Tunnel routes are involved.

## Key workflow

1. Identify current registrar nameservers and authoritative Cloudflare zone:
   - `whois <domain>` for registrar nameservers.
   - `dig +short NS <domain>` via public resolvers for propagation state.
   - Query authoritative nameservers directly (`dig @<ns> ...`) after the registrar switch.
2. Export/copy DNS records from the old Cloudflare zone before changing nameservers.
   - Include apex/www/dev tunnel CNAMEs, MX, SPF/DKIM/DMARC, verification TXT records.
   - Do not assume Cloudflare auto-import got every record; verify on the new authoritative nameservers.
3. Create the zone in the destination account.
   - A token scoped to an existing zone cannot create a new zone that does not yet exist.
   - Required token shape: **User API token** with `Zone:Zone:Edit` and `Zone:DNS:Edit`, resource scope `All zones` for the destination account.
   - Error `Requires permission "com.cloudflare.api.account.zone.create"` means the token lacks zone-create authority; creating the zone manually in the dashboard is a valid unblocker.
4. Update registrar nameservers only after the destination zone contains equivalent DNS records, or be ready to add missing records immediately.
5. During propagation, check both:
   - recursive resolvers (`dig @1.1.1.1 NS <domain>`, `dig @8.8.8.8 ...`) for cache state;
   - new authoritative nameservers (`dig @holly.ns.cloudflare.com A <domain>`) for the truth once delegation flips.

## Tunnel-specific pitfalls

Cloudflare Tunnel DNS routes are account/zone sensitive:

- `cloudflared tunnel route dns` uses the zone associated with the origin cert token. If the domain is not in that account, it may create surprising records under a different zone (for example `oghmanotes.ie.semyon.ie`) instead of the intended domain.
- `cloudflared tunnel list/info` with `TUNNEL_ORIGIN_CERT=<cert>` is useful for comparing old vs new accounts.
- A copied CNAME to an old account tunnel (`<uuid>.cfargotunnel.com`) can keep service alive during migration if the old tunnel is still connected.
- True migration is not complete until the destination-account tunnel is connected and DNS points at that destination tunnel UUID.

## Verification checklist

- WHOIS nameservers show the new assigned Cloudflare nameservers.
- New authoritative nameservers answer for apex, `www`, important subdomains, MX, DKIM, DMARC, SPF/TXT.
- Recursive resolvers gradually switch from old NS to new NS.
- `cloudflared tunnel info <name>` shows active connector(s) for the tunnel that DNS points to.
- If using Google Workspace mail, MX/DKIM/DMARC remain present; moving Cloudflare accounts does not cancel or replace Workspace billing.

## Post-move cleanup: resources left behind in the source account

A zone can show `status: "moved"` in the source account while useful account-scoped resources still remain there. Do not stop after DNS verification; inventory account-level products too:

```bash
npx wrangler whoami
npx wrangler d1 list
npx wrangler r2 bucket list
npx wrangler queues list
npx wrangler kv namespace list
```

For a deeper account inventory, call the Cloudflare REST API with the current Wrangler OAuth token or a user token and check:

- `/accounts/{account_id}/r2/buckets`
- `/accounts/{account_id}/queues`
- `/accounts/{account_id}/d1/database`
- `/accounts/{account_id}/workers/scripts`
- `/zones?name=<domain>` plus `/zones/{zone_id}/dns_records`

Common outcome: DNS and HTTP are already working from the destination account, but R2 buckets and Queues created during development remain in the old/source account. Migrate those separately; Cloudflare zone moves do not move account-scoped resources.

For R2 migration, count objects and bytes before copying, then verify the destination bucket after copy. Queue migration usually means recreating queue names/settings/consumers and updating the app's Cloudflare account credentials; queued messages themselves should be treated as ephemeral unless the product explicitly needs replay.

## Mail cutover caveat

If a domain was using Google Workspace and the goal is to stop paying for Workspace, DNS migration alone is not enough. Check public MX records:

```bash
dig +short MX <domain> @1.1.1.1
dig +short TXT _dmarc.<domain> @1.1.1.1
```

If MX still points at Google (for example `smtp.google.com`), cancelling Workspace will break inbound mail unless you first switch to another receiver. Cloudflare Email Routing can forward inbound mail to a verified personal mailbox, but it is not a mailbox and does not provide normal outbound "send as" mail. Preserve SPF/DKIM/DMARC and verification TXT records during the cutover.