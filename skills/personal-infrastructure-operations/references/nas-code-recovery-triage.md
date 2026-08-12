# NAS code-recovery triage and safe pruning

Use after discovering multiple NAS copies of code: canonical tree, server backup, laptop/Windows dumps, and copied agent worktrees.

## Goal

Preserve real uncommitted work without overwriting active `~/code` repos or retaining every stale duplicate forever.

## Phase 1: inventory and compact recovery

1. Scan only project-code paths (`code`, `projects`, `project_files`, `worktrees`), excluding editor/runtime/vendor trees such as `.local`, `.config`, `AppData`, `node_modules`, virtualenvs, caches, toolchains, and copied Git internals.
2. For each usable repo, record source path, HEAD, normalized origin, tracked dirty count, non-ignored untracked paths, and `git diff HEAD --binary` SHA-256.
3. Do not let copied worktree metadata block preservation. For normal repos, create a compact recovery bundle containing:
   - `tracked.patch`;
   - copied non-ignored untracked files;
   - source/head/origin metadata and hashes.
4. For broken/no-HEAD/timeout worktrees, retain an excluded-dependency raw working-tree tar with a SHA-256 and a bounded manifest. Never silently omit them.
5. Verify every created artifact. Keep live repos and NAS sources read-only.

## Phase 2: evidence-based comparison

1. Deduplicate conclusions by `(origin, source HEAD, tracked-patch hash)`, but retain every original source row.
2. Find same-origin active repositories under `~/code`; prefer exact project-relative path to a name-only match.
3. `ALREADY_PRESENT` requires equal patch hash **and** untracked content equivalence. An older source commit is not proof that dirty work landed.
4. For remaining same-origin candidates, use a disposable clone/worktree outside active repos:
   - run `git apply --check <tracked.patch>` against current active HEAD;
   - if direct apply fails, test `git apply --3way` only in the disposable clone;
   - inspect changed paths and bounded history before making a conclusion.
5. Classify concrete outcomes:
   - `APPLY_CANDIDATE`: clean or inspectable 3-way application; review on a new branch later.
   - `CONFLICTS_WITH_CURRENT`: retain as an intent/reference archive; manual port only.
   - `ARCHIVE_ONLY`: no meaningful recoverable delta or unneeded tool/editor state.
   - `REVIEW_FOR_CONTENT`: no reliable active destination; preserve selected coursework/docs/source only.
   - `HIGH_REVIEW_RAW` / `LIKELY_NOISE_RAW`: raw fallback handling based on bounded manifest and worktree name.
6. Treat `.env`, service-account, credential, or private-key-shaped files as retain-but-isolate. Never classify them as deletion-safe merely because their surrounding code is stale.

## Pruning

- Delete only **recovery artifacts**, never the NAS source or active repo, after explicit approval.
- First prune `ALREADY_PRESENT`, proved superseded items, and pure noise. Write a receipt listing exact bundle/tar paths and classifications; verify every target is gone.
- Defer `APPLY_CANDIDATE`, `CONFLICTS_WITH_CURRENT`, `REVIEW_FOR_CONTENT`, and high-value raw worktrees until a user-directed review or retention decision.

## Reporting

State the classification counts, key active projects, secrets kept isolated, exact receipt paths, and the distinction between "cleanly test-applies" and "should be merged."