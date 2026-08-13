---
name: html-communication
description: "Use when the user asks for a plan, spec, writeup, findings, report, comparison, or UI mockup to read outside the terminal, or says HTML without more context. Produce one standalone HTML document; do not use for product HTML."

metadata:
  harness: [claude, codex]
---

# HTML communication

Create a readable standalone HTML artifact for a human. This is communication material, not product HTML.

1. Do not use this for HTML that ships as part of the application.
2. Create one self-contained HTML document, capped at 512 KB unless the user asks otherwise.
3. Write it like a clear spec/report, not a landing page: obvious hierarchy, concise prose, direct evidence, and no decorative product marketing.
4. When presenting UI alternatives, label them A, B, C and lay them out for direct comparison.
5. Keep a stable local source path across revisions so the same Seol page can be updated when the user wants a stable review URL.
6. Use `seol` only if the user asks to share/publish it. Do not claim it is hosted or inspect it in a browser before upload succeeds; browser verification is only needed after a successful publish or when the user asks.

## Done

Give the local artifact path. If published, return the verified Seol URL and say it is temporary.
