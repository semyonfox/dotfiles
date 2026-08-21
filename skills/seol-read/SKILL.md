---
name: seol-read
description: Use when the user supplies a Seol page URL and asks to read, inspect, summarise, or use its published content.

metadata:
  harness: [claude, codex]
---

# Seol read

Fetch the supplied Seol URL with the shell. Do not use a browser or web search.

1. Fetch the exact URL directly:

   ```bash
   curl --fail --silent --show-error --location --max-time 30 URL
   ```

2. Use the fetched content to answer the request. Report fetch failures plainly.
3. Reading never mutates, replaces, extends, or republishes a page.
