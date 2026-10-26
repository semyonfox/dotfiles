---
name: file-pr
description: Use when the user asks to file, open, or create a PR. Files a concise PR that leads with the problem.

metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
---

# File PR

Before filing, check whether a PR for this branch already exists. Review the
diff locally against the PR's base branch (the repo default, for example
`origin/main` or `origin/master`) to make sure its contents match the goal.

PR titles usually become commit messages, so follow the repository's title
conventions. Look at recently merged PRs and Git history for examples. Prefer a
concise, human-readable title that explains why the change matters:

Bad:

> perf(server): negotiate permessage-deflate on the websocket

Good:

> perf(server): cut websocket frame size by 70%+ with gzipping

Open the description with a simple explanation of the problem based on the
user's original prompt, then briefly explain the solution. Do not lead with an
implementation inventory:

Bad:

> Removed implicit workspace carry-over from every "new thread" entry point (cmd+n / cmd+shift+o, sidebar v1/v2 buttons, command palette). New threads inherit only the project from context. Branch, worktree, and env mode always come from the configured defaults. Deleted buildContextualThreadOptions, startNewThreadInProjectFromContext, and the v1 sidebar's seed-context machinery.

Good:

> My "new worktree" default was ignored when starting new threads on existing worktrees. Super unintuitive. Now your preferences always apply.

Attribution follows the rule in global guidance. Only when the repo has
`attribution: on`, end the description with the public model name and harness
that made the changes, for example `Created with <model> in <harness>.` Include
subagent models that wrote part of the change. Use the model name the harness
reports. If model identity is unavailable, name the harness without guessing a
model. Otherwise leave out any model or harness line.

Before submission, check the title, description, quotes, and attachments for
secrets and private details.

Open a real PR rather than a draft so review bots run. If `gh pr create` fails
because the GraphQL rate limit is used up, open it through REST with
`gh api repos/<owner>/<repo>/pulls -f title=... -f head=... -f base=... -F body=@<file>`. If the user also asked
to babysit it, continue with the `babysit-pr` skill.

Do not post a follow-up PR comment unless it serves the user's request. When a
comment is needed, follow `babysit-pr`.
