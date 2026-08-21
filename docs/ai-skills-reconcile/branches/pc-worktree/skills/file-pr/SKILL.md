---
name: file-pr
description: "Use when the user asks to file, open, or create a PR."

metadata:
  harness: [claude, codex]
---

# File PR

<!-- Body transcribed/adapted only from the video passage at 00:15:04–00:17:45. Frontmatter is structural metadata, not spoken video text. -->

Before filing, check whether this branch already has a PR and review its diff against `origin/main` to confirm it matches the goal.

Follow the repository's title conventions by checking merged PRs and Git history. Titles often become commit messages: make them concise, human-readable, and explain why the change matters.

Bad:

> Perf server negotiate per message deflate on the WebSocket

Good:

> Perf server cut WebSocket frame size by 70% with gzipping

Start the description with the problem from the user's prompt, then briefly explain the solution—not an implementation inventory.

Bad:

> Removed implicit workspace carryover from every new thread entry point. New threads inherit only the project from context. Branch, work tree, ...

Good:

> My new work tree default was ignored when starting new threads on existing work trees. Super unintuitive. Now your preferences always apply.

Open a real PR, not a draft, so review bots run. If it needs monitoring, use `babysit-pr`. End the description with the model and harness that made the changes.
