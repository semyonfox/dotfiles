# Stale PR salvage and conflict drift

Use when a PR is marked conflicted/dirty but likely overlaps work already merged to the base branch.

## Goal

Avoid blindly resolving conflicts in favour of either side. Determine what is already on the base branch, what is truly still useful, and rebuild a small fresh PR from the current base when that is safer.

## Workflow

1. Fetch the base and PR branch.
2. Identify the merge base:
   ```bash
   mb=$(git merge-base origin/dev origin/topic-branch)
   ```
3. Inspect current conflicts without touching the working tree:
   ```bash
   git merge-tree --write-tree --messages --name-only origin/dev origin/topic-branch
   ```
4. Compare history to find duplicated/superseded commits:
   ```bash
   git range-diff "$mb"..origin/topic-branch "$mb"..origin/dev -- <relevant paths>
   git log --oneline --decorate "$mb"..origin/topic-branch
   git log --oneline --decorate "$mb"..origin/dev -- <relevant paths>
   ```
5. Split changes into:
   - **keep from base**: newer implementation already supersedes the PR
   - **salvage from PR**: still-useful bug fixes/tests/config moved cleanly onto base
   - **skip/split later**: unrelated UI/TODO work, broad feature drift, stale generated output
6. Prove the salvage path in an isolated worktree from current base:
   ```bash
   git worktree add /tmp/repo-salvage --detach origin/dev
   cd /tmp/repo-salvage
   git diff --binary <base-equivalent-commit>..<stale-pr-head> -- <selected paths> | git apply --3way
   ```
7. If clean, create a fresh branch from current base and apply only selected paths. Do not merge the stale PR branch as-is.
8. Run focused tests, lint changed files, build/typecheck, inspect diff, then open a replacement draft PR.
9. Comment on or close/supersede the stale PR only after the replacement PR exists and is linked.

## Common pitfall

A dirty PR can be mostly harmless drift: an older branch may contain a commit whose main idea already landed differently on base. In that case resolving conflicts manually preserves too much stale shape. Prefer a fresh salvage PR with only the remaining delta.

## Client/server import pitfall

When salvaging observability into code used by client components, do not import server-only loggers/transports into browser-reachable modules. If a logger pulls `fs`, `winston`, `node:async_hooks`, or rotating file transports into a client import trace, Next/Turbopack builds will fail. Preserve feature intent by using a browser-safe surface, e.g. `console.warn` plus a metric hook, or by splitting client/server logging modules.

## Reporting pattern for Semyon

For multi-item triage, report and request approval one item at a time:

1. Give the concrete recommendation and evidence for the current item.
2. Ask for approve/deny on that item only.
3. If approved, execute and verify.
4. Then present the next item.

Avoid dumping a whole queue of approvals at once unless explicitly asked for a full report.
