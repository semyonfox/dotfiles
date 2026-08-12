# Gmail draft update via local OAuth — July 2026 notes

Session pattern: Semyon wanted a Gmail reply draft edited, explicitly not sent. Correct route was the local personal Google OAuth/Gmail API tooling, not Claude.ai Gmail MCP.

## Durable lessons

- Verify identity first: `gmail-whoami personal` should return `semyon.fox@gmail.com`.
- Draft editing needs more than `gmail.readonly`. If `users.drafts.update` returns `insufficient authentication scopes`, re-authorize the account with Gmail management scopes, e.g.:

```bash
google-auth-account personal --preset gmail-manage --no-browser --port 8765
```

- For headless/server OAuth using Semyon's PC browser:
  1. Start the OAuth helper on the server.
  2. From the PC, forward the callback back to the server:

```bash
ssh -f -N -L 8765:127.0.0.1:8765 server
```

  3. Open the printed Google auth URL in Helium on the PC.
  4. Wait for the helper to save the token and print granted scopes.

- Edit existing drafts with `users.drafts.update` where possible. Preserve:
  - `To` / `Cc`
  - `Subject`
  - `threadId`
  - `In-Reply-To` / `References` headers when present
  - quoted original content / reply context

- After any draft edit, verify both:
  - updated draft body contains the intended text
  - Sent mail search for the same recipient/subject did not change

## Formatting pitfall

Gmail/API plain-text previews may show hard wraps, but the draft can still have normal paragraphs. When a user complains about weird line breaks:

- Join single newlines inside a paragraph into spaces.
- Preserve blank lines between paragraphs.
- Preserve sign-off as separate lines, e.g.:

```text
Le meas,
Semyon Fox
```

Do not introduce forced hard wraps for readability in chat; Gmail composers should receive normal paragraph text.

## Style note

For Semyon, `Le meas,` is an acceptable/preferred Irish sign-off where relevant. Do not automatically replace it with generic `Kind regards,`.
