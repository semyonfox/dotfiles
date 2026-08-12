---
name: seol
description: "Use when the user asks to upload, host, publish, deploy, or share a static artifact through Seol."
---

# Seol publish

Publish a reviewable static artifact to Semyon's Seol service only when the user asks for an external link.

1. Require the documented `seol` CLI on the execution host. Never print its token or configuration.
2. Accept one `.html`/`.htm` file, or a directory/ZIP whose root contains `index.html`. For an application/project, inspect its documented build command and publish the real static output; do not invent a build command.
3. Preserve relative asset paths such as `assets/chart.svg`; never use root-relative paths.
4. Scan the artifact for obvious secrets or sensitive/private data. Stop and flag it rather than publishing if found.
5. Publish using the documented CLI:

```bash
seol publish --quiet PATH
# Optional: --title "Title" --expires 7d
```

6. Keep the local source directory for revision. Publish the same canonical path again when the stable URL should update; use `--new` only when a separate URL is intended.
7. Verify the returned public URL and representative assets before saying it is live.

## Done

Return the URL and actual lifetime. Seol pages are temporary public links, not private storage or permanent hosting.
