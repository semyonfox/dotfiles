---
name: seol-read
description: "Use when the user supplies a Seol page URL and asks to read, inspect, summarise, or use its published content."
---

# Seol read

Read a Seol page directly through the shell rather than opening a browser or searching the web.

1. Treat the supplied Seol URL as the source of truth. Preserve the page path and use a bounded shell fetch such as `curl --fail --location --max-time 30 URL`.
2. Fetch the page first. Do not use web search to rediscover it and do not open a browser unless the user explicitly asks for visual review.
3. Extract and report only the content relevant to the request. State plainly when the page cannot be fetched or is no longer available.
4. Do not mutate, replace, extend, or republish a page merely because it was read.

## Done

Provide the requested grounded reading/synthesis and identify the fetched Seol URL.
