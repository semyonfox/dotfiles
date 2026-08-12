---
name: cloudflare-email-service
description: Send and receive transactional emails with Cloudflare Email Service (Email Sending + Email Routing). Use when building email sending (Workers binding or REST API), email routing, Agents SDK email handling, or integrating email into any app — Workers, Node.js, Python, Go, etc. Also use for email deliverability, SPF/DKIM/DMARC, wrangler email setup, MCP email tools, or when a coding agent needs to send emails. Even for simple requests like "add email to my Worker" — this skill has critical config details.

metadata:
  harness: [hermes]
---

# Cloudflare Email Service

Your knowledge of the Cloudflare Email Service, Email Routing or Email Sending may be outdated. **Prefer retrieval over pre-training** for any Cloudflare Email Service task.

Cloudflare Email Service lets you send transactional emails and route incoming emails, all within the Cloudflare platform. Your knowledge of this product may be outdated — it launched in 2025 and is evolving rapidly. **Prefer retrieval over pre-training** for any Email Service task.

**If there is any discrepancy between this skill and the sources below, always trust the original source.** The Cloudflare docs, REST API spec, `@cloudflare/workers-types`, and Agents SDK repo are the source of truth. This skill is a convenience guide — it may lag behind the latest changes. When in doubt, retrieve from the sources below and use what they say.

## Retrieval Sources

| Source | How to retrieve | Use for |
|--------|----------------|---------|
| Cloudflare docs | `cloudflare-docs` search tool or URL `https://developers.cloudflare.com/email-service/` | API reference, limits, pricing, latest features |
| REST API spec | `https://developers.cloudflare.com/api/resources/email_sending` | OpenAPI spec for the Email Sending REST API |
| Workers types | `https://www.npmjs.com/package/@cloudflare/workers-types` | Type signatures, binding shapes |
| Agents SDK docs | Fetch `docs/email.md` from `https://github.com/cloudflare/agents/tree/main/docs` | Email handling in Agents SDK |

## FIRST: Check Prerequisites

Before writing any email code, verify the basics are in place:

1. **Domain onboarded?** Run `npx wrangler email sending list` to see which domains have email sending enabled. If the domain isn't listed, run `npx wrangler email sending enable userdomain.com` or see [cli-and-mcp.md](references/cli-and-mcp.md) for full setup instructions.
2. **Binding configured?** Look for `send_email` in `wrangler.jsonc` (for Workers)
3. **postal-mime installed?** Run `npm ls postal-mime` (only needed for receiving/parsing emails)

## What Do You Need?

Start here. Find your situation, then follow the link for full details.

| I want to... | Path | Reference |
|--------------|------|-----------|
| **Send emails from a Cloudflare Worker** | Workers binding (no API keys needed) | [sending.md](references/sending.md) |
| **Send emails from an AI agent built with [Cloudflare Agents SDK](https://developers.cloudflare.com/agents/)** | `onEmail()` + `replyToEmail()` in Agent class | [sending.md](references/sending.md) |
| **Send emails from an external app or agent** (Node.js, Go, Python, etc.) | REST API with Bearer token | [rest-api.md](references/rest-api.md) |
| **Send emails from a coding agent** (Claude Code, Cursor, Copilot, etc.) | MCP tools, wrangler CLI, or REST API | [cli-and-mcp.md](references/cli-and-mcp.md) |
| **Receive and process incoming emails** (Email Routing) | Workers `email()` handler | [routing.md](references/routing.md) |
| **Set up Email Sending or Email Routing** | `wrangler email sending enable` / `wrangler email routing enable`, or Dashboard | [cli-and-mcp.md](references/cli-and-mcp.md) |
| **Migrate inbound mail away from Google Workspace** | Email Routing MX cutover + catch-all forwarding; verify routing is enabled, not just rules present | [routing.md](references/routing.md) |
| **Improve deliverability, avoid spam folders** | Authentication, content, compliance | [deliverability.md](references/deliverability.md) |

## Email Routing cutover from Google Workspace / existing MX

Cloudflare Email Routing is forwarding-only inbound mail. It can catch service emails to arbitrary aliases when a catch-all rule forwards to a verified destination, but it is not a mailbox and does not provide normal outbound mailbox sending.

For a domain currently on Google Workspace or another mail host:

1. Verify the destination address first (`wrangler email routing addresses create ...` or Dashboard).
2. Create/confirm the catch-all or address rules.
3. Get required records with `wrangler email routing dns get <domain>`.
4. Remove the old MX records and add Cloudflare's MX records. Do **not** leave the domain with no MX.
5. Add the Cloudflare SPF/DKIM TXT records shown by the command.
6. Enable routing and verify `wrangler email routing settings <domain>` shows enabled/configured.

Pitfalls:

- `wrangler email routing enable <domain>` fails with `Non-Cloudflare MX records exist [code: 2008]` while old MX records are still present.
- When giving a user a DNS import file, make it **email-only** and explicitly warn not to replace the whole zone. Keep app DNS records intact.
- Wrangler OAuth with `email_routing:write` may still be insufficient for raw DNS record edits; use Dashboard or a token with `Zone:DNS:Edit` for MX/TXT changes.
- Before cancelling Google Workspace, export historical mailbox contents separately; DNS forwarding does not migrate old mail.

## Quick Start — Workers Binding

Add the binding to `wrangler.jsonc`, then call `env.EMAIL.send()`. The `from` domain must be onboarded via `npx wrangler email sending enable yourdomain.com`.

```jsonc
// wrangler.jsonc
{ "send_email": [{ "name": "EMAIL" }] }
```

```typescript
const response = await env.EMAIL.send({
  to: "user@example.com",
  from: { email: "welcome@yourdomain.com", name: "My App" },
  subject: "Welcome!",
  html: "<h1>Welcome!</h1>",
  text: "Welcome!",
});
```

The binding is recommended for Workers — no API keys needed. If a user specifically requests the REST API from within a Worker (e.g., they already have an API token workflow), that works too — see [rest-api.md](references/rest-api.md).

See [sending.md](references/sending.md) for the full API, batch sends, attachments, custom headers, restricted bindings, and Agents SDK integration.

## Quick Start — REST API

For apps outside Workers, or within Workers if the user explicitly requests it. Key differences from the Workers binding:

- Endpoint: `POST https://api.cloudflare.com/client/v4/accounts/{account_id}/email/sending/send`
- `from` object uses `address` (not `email`): `{ "address": "...", "name": "..." }`
- `replyTo` is `reply_to` (snake_case)
- Response returns `{ delivered: [], permanent_bounces: [], queued: [] }` (not `messageId`)

See [rest-api.md](references/rest-api.md) for curl examples, response format, and error handling.

## Public-domain alias rollout (portfolio, CV, and personal sites)

When replacing a publicly listed personal inbox with an alias such as `hello@yourdomain.com`, complete routing **before** publishing the new address. A safe rollout is:

1. Inspect the live MX/SPF records and `wrangler email routing settings <domain>` first. Do not infer that a dashboard’s displayed required records are live.
2. Reuse an already verified destination address where possible; otherwise create and verify it before touching MX.
3. Create the explicit alias rule first (for example `hello@yourdomain.com → personal@example.com`) and leave catch-all disabled unless the user explicitly wants it.
4. If `wrangler email routing enable` returns `Non-Cloudflare MX records exist`, remove/replace the old MX and root SPF records in DNS, then enable routing. An OAuth session with `email_routing:write` can still lack `Zone:DNS:Edit`; do not try to work around that with broad credentials or assume the CLI can edit the records. Have the domain owner make the bounded DNS change in the Dashboard if necessary.
5. Verify all three Cloudflare MX records and Cloudflare SPF through a public resolver, then verify `Enabled: true` and `Status: ready` in Email Routing.
6. Send a real test to the alias and confirm receipt at the destination before deploying a site/CV change.
7. Update every public occurrence, including `mailto:` links, CV data, legal/privacy contacts, Markdown/AI discovery pages, and API/OpenAPI contact metadata. Build and scan the generated output for the old address before deployment.

Cloudflare’s edge Email Address Obfuscation can replace the visible address with `data-cfemail`/a protection link in fetched HTML. When verifying the public page, decode those values or inspect the origin container as well as checking raw text; raw-address searches alone may produce a false negative.

## Replacing Google Workspace with Cloudflare forwarding

When the user wants to stop paying for Google Workspace but keep receiving mail for a domain, first verify the live MX records before touching anything:

```bash
dig +short MX example.com @1.1.1.1
dig +short TXT _dmarc.example.com @1.1.1.1
```

If MX still points at Google (for example `smtp.google.com`), cancelling Workspace will break inbound mail unless another receiver is configured first. Cloudflare Email Routing is a good lightweight inbound-forwarding replacement:

1. Enable Email Routing on the destination Cloudflare account's zone.
2. Add and verify the user's personal mailbox as a destination address.
3. Create explicit routes for important addresses (`contact@`, `hello@`, etc.) and optionally a catch-all.
4. Let Cloudflare install/replace the MX records, then verify public DNS.
5. Preserve SPF/DKIM/DMARC and service-verification TXT records unless intentionally retiring the service.
6. Tell the user to export old Workspace mailbox contents before cancelling; Email Routing does not migrate historical mail.

Be clear about the tradeoff: Email Routing forwards inbound mail only. It is not a mailbox and does not provide ordinary outbound "send as" email. For outbound human mail, keep Workspace or use another mailbox/SMTP provider. For app-generated transactional mail, use Cloudflare Email Sending or another transactional provider.

## Common Mistakes

| Mistake | Why It Happens | Fix |
|---------|---------------|-----|
| Assuming a catch-all rule means Email Routing is active | Rules can exist while the zone remains `unconfigured` because non-Cloudflare MX records still point elsewhere | Replace old MX records with Cloudflare Email Routing MX records, then verify `wrangler email routing settings <domain>` shows `Enabled: true` and `Status: ready` |
| Deleting the old MX without adding Cloudflare MX | During Workspace-to-forwarding cutovers, removing Google MX alone leaves the domain unable to receive mail | Replace Google MX with the three Cloudflare MX records in the same change; do not leave an empty MX state |
| Proxying mail records | Cloudflare proxy only applies to HTTP(S) records, not mail routing | Keep MX, SPF TXT, DKIM TXT, and DMARC TXT as DNS-only / unproxied |
| Trying to enable Email Routing while Google/other MX records still exist | Cloudflare refuses to activate routing when non-Cloudflare MX records are present | Delete/replace old MX records first, add Cloudflare's MX records, then run `wrangler email routing enable <domain>` and verify `Status: ready` |
| Proxying email DNS records | MX/TXT/DKIM/DMARC are not HTTP traffic and cannot/should not be orange-clouded | Keep all mail-related records DNS-only / grey-cloud |
|---------|---------------|-----|
| Forgetting `send_email` binding in wrangler config | Email Service uses a binding, not an API key | Add `"send_email": [{ "name": "EMAIL" }]` to wrangler.jsonc |
| Sending from an unverified domain | Domain must be onboarded onto Email Sending before first send | Run `wrangler email sending enable yourdomain.com` or onboard in Dashboard |
| Reading `message.raw` twice in email handler | The raw stream is single-use — second read returns empty | Buffer first: `const raw = await new Response(message.raw).arrayBuffer()` |
| Missing `text` field (HTML only) | Some email clients only show plain text; also helps spam scores | Always include both `html` and `text` versions |
| Using email for marketing/bulk sends | Email Service is for transactional email only | Use a dedicated marketing email platform for newsletters and campaigns |
| Forwarding to unverified destinations | `message.forward()` only works with verified addresses | Run `wrangler email routing addresses create user@gmail.com` or add in Dashboard |
| Assuming a catch-all rule means mail is live | Email Routing rules can exist while the zone is still disabled/unconfigured, especially during MX migrations | Check `wrangler email routing settings <domain>` and public MX; enable routing only after Cloudflare MX/TXT records replace old provider records |
| Leaving old Google Workspace MX in place | Cloudflare Email Routing refuses to enable when non-Cloudflare MX records exist (`Non-Cloudflare MX records exist`) | Remove/replace Google MX with Cloudflare Routing MX records in DNS, then enable routing and verify public MX |
| Expecting Email Routing to replace a mailbox | Routing forwards inbound mail only; it does not migrate history or provide normal outbound mailbox sending | Export old mailbox data separately; use Workspace/SMTP/Email Sending for outbound depending on use case |
| Testing with fake addresses | Bounces from non-existent addresses hurt sender reputation | Use real addresses you control during development |
| Hardcoding API tokens in source code | Tokens in code get committed and leaked | Use environment variables or Cloudflare secrets |
| Ignoring the `from` domain requirement | The `from` address must use a domain onboarded to Email Service | Verify the domain first, then send from `anything@that-domain.com` |
| Using `email` key in REST API `from` object | REST API uses `address` not `email` for `from` object | Use `{ "address": "...", "name": "..." }` for REST, `{ "email": "...", "name": "..." }` for Workers |
| Using `replyTo` in REST API | REST API uses snake_case field names | Use `reply_to` for REST API, `replyTo` for Workers binding |

## References

Read the reference that matches your situation. You don't need all of them.

- **[references/sending.md](references/sending.md)** — Workers binding API, attachments, Agents SDK email. For Workers or Agents SDK.
- **[references/rest-api.md](references/rest-api.md)** — REST endpoint, curl examples, error handling. For apps NOT on Workers.
- **[references/routing.md](references/routing.md)** — Inbound `email()` handler, forwarding, replying, parsing. For receiving emails.
- **[references/cli-and-mcp.md](references/cli-and-mcp.md)** — Domain setup, wrangler commands, MCP tools. For first-time setup.
- **[references/deliverability.md](references/deliverability.md)** — SPF/DKIM/DMARC, bounces, suppressions, best practices.
