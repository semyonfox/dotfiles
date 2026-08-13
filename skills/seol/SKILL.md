---
name: seol
description: "Use when the user asks to publish or share a static artifact through Seol. Upload a safe HTML file, archive, or static-site directory to a temporary URL."

metadata:
  harness: [codex]
---

# Seol

Publish only when requested; this is an external side effect.

1. Require `seol` on `PATH`.
2. Accept one `.html`/`.htm` file, or a directory/ZIP with root `index.html`.
3. For framework source, inspect its scripts/docs; when useful, run its existing
   production build and upload the static output (`dist/`, `build/`, etc.). Never
   invent an unknown build command.
4. Check text for obvious credentials or sensitive data; stop and warn if found.
5. Preserve relative assets (`assets/app.js`, not `/assets/app.js`).
6. Publish and return the printed URL:

```bash
seol publish --quiet PATH
# Optional: --expires 7d --title "Title"
```

Omit `--expires` for the one-day default unless the user requests another
duration; seven days is the maximum. Publishing requires the configured server
token. If the server is not configured, ask the user to run:

```bash
seol configure --server URL --token TOKEN
```

Never print the token or configuration. Manage only when requested:

```bash
seol list
seol stats
seol info PAGE_ID
seol replace PAGE_ID PATH
seol expiry PAGE_ID 3d
seol delete PAGE_ID
```
