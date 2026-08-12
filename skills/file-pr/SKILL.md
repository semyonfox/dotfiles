---
name: file-pr
description: "Use when the user asks to file, open, or create a PR."

metadata:
  harness: [claude, codex]
---

# File PR

<!-- Body transcribed/adapted only from the video passage at 00:15:04–00:17:45. Frontmatter is structural metadata, not spoken video text. -->

Before filing, check whether a PR for this branch already exists. Review the diff locally against `origin/main` to make sure its contents match the goal.

PR titles usually become commit messages, so follow the repository's title conventions. Look at recently merged PRs and Git histories. Prefer a concise, human-readable title that explains why the changes matter.

Bad:

> Perf server negotiate per message deflate on the WebSocket

Good:

> Perf server cut WebSocket frame size by 70% with gzipping

Open the description with a simple explanation of the problem based on the user's original prompt, then briefly explain the solution. Do not lead with an implementation inventory.

Bad:

> Removed implicit workspace carryover from every new thread entry point. New threads inherit only the project from context. Branch, work tree, ...

Good:

> My new work tree default was ignored when starting new threads on existing work trees. Super unintuitive. Now your preferences always apply.

Stop opening draft PRs. Open a real PR rather than a draft so review bots run. If the user also has to babysit it, continue with the `babysit-pr` skill.

Add a blurb to the end of the PR description about what model and harness made the changes.
