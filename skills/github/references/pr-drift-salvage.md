# PR drift salvage

Use when an old/conflicted PR probably overlaps work that already landed on the base branch. Goal: avoid blind conflict resolution, preserve useful residual changes, and prevent regressions.

## Workflow

1. Fetch base and PR branches.
2. Identify the merge base and compare history:
   - `git merge-base origin/<base> origin/<pr-branch>`
   - `git range-diff <merge-base>..origin/<pr-branch> <merge-base>..origin/<base>`
   - inspect equivalent/similar commits already on base.
3. Simulate merge conflicts without touching the main worktree:
   - `git merge-tree --write-tree --messages --name-only origin/<base> origin/<pr-branch>`
4. Separate changes into:
   - **already landed / superseded**: keep base version
   - **useful residual delta**: salvage onto fresh branch from current base
   - **unrelated side quest**: split or skip
   - **regression risk**: explicitly compare behavior before choosing
5. For stale PRs, prefer a fresh replacement branch from current base:
   - create isolated worktree from `origin/<base>`
   - apply only residual useful delta, often via `git diff <landed-equivalent>..<old-pr-head> | git apply --3way`
   - exclude unrelated files intentionally
6. Verify with focused tests, lint/typecheck/build, and CI after pushing.
7. Open a new draft PR explaining exactly what was kept, skipped, and why. Before merge, answer the user's regression questions explicitly: what base currently does, what the stale PR would change, whether any feature is lost, and which checks prove it.
8. After the replacement merges, clean up the deprecated path: comment on/close the old PR as superseded, delete the old remote branch if it belongs to the user's repo, remove temporary worktrees/branches, and fast-forward the main local worktree to the merged base.

## Regression guard: behavior superseded by base

When base has a newer implementation of the same feature, do not let the stale PR overwrite it. Compare behavior directly.

Example pattern from Oghma chat tool-call limits:

- Current base had `src/lib/chat/tool-budget.ts`, wrapping tools with a budget. When exhausted, a synthetic tool result tells the model to continue with gathered info. Final response carries `partial: true`, `error`, and `toolCallLimitHit: true`, and streaming sends a final token plus `done`.
- Old stale PR had inline route handling that called `sendError(...)` / returned `502` when `finishReason === "tool-calls"`. That was a regression because it hard-failed instead of preserving partial progress.
- Correct salvage: keep base tool-budget files and route/build-stream behavior; salvage only unrelated useful RAG/SSE/chunking changes.

## Client/server import guard

When salvaging observability into client-imported modules, check import traces. Do not import server-only loggers or Node-only dependencies into client bundles. Prefer browser-safe `console.warn` plus existing metric hooks, or split server/client logging modules.

## Worktree dependency/build guard

If a Node/Next/Vite worktree lacks dependencies, symlinking `node_modules` from another worktree may be enough for quick unit tests but can break production builds or bundlers that enforce project-root boundaries. If a build fails because a symlink points outside the filesystem/project root, remove the symlink and run the repo's package install in the worktree, then rerun focused tests and the real build before pushing.

## Reporting style for Semyon

For approval flows, present one approval/deny item at a time. If a full report is requested, still end with one clear next action. Include enough context to judge feature loss/regression risk: what current base does, what old PR does, what is kept/skipped/changed, and real verification output.