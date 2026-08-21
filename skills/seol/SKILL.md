---
name: seol
description: Use when the user asks to publish, host, upload, deploy, or share an HTML file, ZIP, or static site as a temporary public URL.

metadata:
  harness: [claude, codex]
---

# Seol

Publish only when requested; this is an external side effect.

1. Require `seol` on `PATH`.
2. Accept one `.html`/`.htm` file, or a directory/ZIP with root `index.html`.
3. For framework source, inspect its scripts/docs; when useful, run its existing production build and upload the static output (`dist/`, `build/`, etc.). Never invent an unknown build command.
4. Check text for obvious credentials or sensitive data. Stop and warn if found; do not publish it.
5. Preserve relative assets (`assets/app.js`, not `/assets/app.js`).
6. Publish and return the printed URL:

```bash
seol publish --quiet PATH
# Optional: --expires 7d --title "Title"
```

Omit `--expires` for the one-day default unless the user requests another duration. Seven days is the maximum. Publishing needs the configured accountless publisher credential; if unavailable, ask the user to run:

```bash
seol configure --server URL --token TOKEN
```

Never print the token or configuration. Only manage pages on request:

```bash
seol list
seol stats
seol info PAGE_ID
seol replace PAGE_ID PATH
seol expiry PAGE_ID 3d
seol delete PAGE_ID
```
