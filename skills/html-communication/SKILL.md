---
name: html-communication
description: "Use when asked for a plan, spec, writeup, findings, report, comparison, UI mockup, or just HTML to read outside the terminal — not product HTML."

metadata:
  harness: [claude, codex]
---

# HTML communication

Create a readable standalone HTML artifact for a human, not product HTML.

1. Do not use it for HTML that ships with the application.
2. Produce one self-contained document, at most 512 KB unless requested otherwise.
3. Write a clear spec/report—not a landing page—with obvious hierarchy, concise prose, direct evidence, and no decorative product marketing.
4. Label UI alternatives A, B, C and lay them out for comparison.
5. Keep a stable local source path across revisions so the same Seol page can be updated for a stable review URL.
6. Use `seol` only on a request to share/publish. Do not claim hosting or inspect it in a browser before upload succeeds; browser verification is needed only after successful publishing or on request.

Return the local artifact path. If published, return the verified temporary Seol URL.
