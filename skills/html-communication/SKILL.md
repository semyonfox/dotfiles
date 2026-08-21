---
name: html-communication
description: Create a standalone HTML document when the user wants a plan, report, comparison, or mockup to read outside the terminal, not product HTML.

metadata:
  harness: [claude, codex, opencode, cursor]
---

# HTML communication

Create a self-contained, responsive document for a human to read. Do not use this skill for HTML that ships with an application.

- Keep it under 512 KB unless the user asks otherwise. Use semantic HTML and inline CSS.
- Write it like a report or spec: dense, scannable, evidence-led, and free of marketing treatment. Default to black, white text, and dark-gray secondary surfaces.
- Make it usable on a phone. Do not use fixed-width layouts.
- Do not put secrets, private URLs, or local filesystem paths in the page.
- For UI variants, render real alternatives, label them `A`, `B`, and `C`, and lay them out for comparison.
- For a page intended for Seol, keep it passive: no scripts, forms, frames, embeds, or network-dependent content. Use relative asset paths.

Return the local artifact path. If the user asks to share or publish it, use the `seol` skill. Keep the same absolute source path across revisions so Seol can update the existing review URL.
