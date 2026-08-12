# Agent-Friendly Site Patterns

## Discovery Checklist

- `robots.txt`: allow useful search/user-delegated agents; optionally disallow training crawlers. Do not rely on robots for secrecy.
- Sitemap: list canonical HTML pages.
- `llms.txt`: curated Markdown map with short context and links to canonical high-value pages.
- Markdown variants: provide explicit `.md` URLs or content negotiation with `Accept: text/markdown`.
- JSON-LD: add `Person`, `WebSite`, `ContactPage`, `BlogPosting`, and `SoftwareSourceCode` or `CreativeWork` where useful.
- API catalog: expose `/.well-known/api-catalog` when public APIs exist.
- OpenAPI: document JSON action endpoints with examples, limits, error responses, and anti-abuse policy.
- Human docs: every machine endpoint should have a human-readable docs page.

## Contact Architecture

Prefer this flow:

1. Agent discovers `/contact` or `/api/contact-intents` from `llms.txt`, HTML links, JSON-LD, and OpenAPI.
2. Agent submits a contact intent with sender name, sender email, reason, message, optional source, and idempotency key.
3. Server stores the intent as pending.
4. Server emails the sender a verification link.
5. Message is delivered or queued for moderation only after verification.

Useful JSON payload:

```json
{
  "name": "Jane Recruiter",
  "email": "jane@example.com",
  "reason": "internship",
  "message": "A user asked me to contact Semyon about an internship role.",
  "source": "user-delegated-agent",
  "idempotency_key": "c01c7212-9e1d-4785-8a08-f105cc63d192"
}
```

Useful response:

```json
{
  "status": "pending_verification",
  "next_step": "A verification link has been sent to the sender email. The message is delivered only after verification."
}
```

## Spam-Safe Controls

Use several low-friction controls instead of one brittle gate:

- Rate limit by IP, email, email domain, and message fingerprint.
- Require sender email verification before delivery.
- Add an invisible honeypot field to HTML forms.
- Limit message length and link count.
- Reject obviously commercial spam categories when the site owner does not want them.
- Keep a moderation queue for low-trust or high-risk messages.
- Add Turnstile or CAPTCHA for browser submissions when spam appears, but avoid making CAPTCHA the only documented agent path.
- Use idempotency keys to avoid duplicate submissions from retrying agents.
- Log enough to debug abuse without storing raw IPs longer than needed.

## Semantic HTML Form

Browser agents work best with normal HTML:

```html
<form method="post" action="/api/contact-intents">
  <label for="contact-name">Name</label>
  <input id="contact-name" name="name" autocomplete="name" required />

  <label for="contact-email">Email</label>
  <input id="contact-email" name="email" type="email" autocomplete="email" required />

  <label for="contact-reason">Reason</label>
  <select id="contact-reason" name="reason" required>
    <option value="collaboration">Collaboration</option>
    <option value="recruiting">Recruiting</option>
    <option value="question">Question</option>
  </select>

  <label for="contact-message">Message</label>
  <textarea id="contact-message" name="message" required></textarea>

  <input name="_gotcha" tabindex="-1" autocomplete="off" hidden />
  <button type="submit">Send message</button>
</form>
```

## `llms.txt` Shape

Keep it short and curated:

```md
# Site Name

Brief site purpose and owner summary.

## Canonical Pages

- [Home](https://example.com/)
- [Projects](https://example.com/projects)
- [CV](https://example.com/cv)

## Markdown

- [Home Markdown](https://example.com/index.md)
- [Projects Markdown](https://example.com/projects.md)

## Agent Actions

- Contact intent API: `POST https://example.com/api/contact-intents`
- OpenAPI: `https://example.com/api/contact/openapi.json`
- Sender verification is required before delivery.
- Do not scrape or use raw email addresses.
```

## Robots Policy Pattern

For user-delegated agent access, distinguish search/user agents from training crawlers where vendors support separate user agents.

Example shape, verify names against current official docs before committing:

```txt
User-agent: OAI-SearchBot
Allow: /

User-agent: ChatGPT-User
Allow: /

User-agent: Claude-User
Allow: /

User-agent: Claude-SearchBot
Allow: /

User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: *
Allow: /

Sitemap: https://example.com/sitemap-index.xml
```

## Acceptance Tests

- `curl -I /llms.txt` returns `200` and `text/plain` or `text/markdown`.
- `curl -H 'Accept: text/markdown' /some-page` returns Markdown and `Vary: Accept`.
- `/.well-known/api-catalog` returns `application/linkset+json` if APIs are advertised.
- OpenAPI validates with a current parser.
- Contact form is usable without JavaScript.
- Honeypot submissions are ignored.
- Unverified contact intents are not delivered.
- Rate limits return `429`.
- CORS is restricted unless there is a deliberate cross-origin use case.
- Machine-readable surfaces do not expose raw private email unless intentionally allowed.
