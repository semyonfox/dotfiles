# NAS Git recovery triage and repository-only cleanup

Use for recovered NAS/device-dump code where the goal is to preserve only real unrecovered work, compare it with active repositories, and later remove recovery scaffolding safely.

## Audit scope

1. Search project-code paths (`code`, `projects`, `project_files`, `worktrees`) rather than blindly treating editor/plugin/vendor trees as user repositories.
2. Exclude dependency/tool trees such as `node_modules`, virtualenvs, package stores, `.local`, `.config`, caches, and platform app-data roots unless explicitly requested.
3. For every usable repo, record source path, origin, verified `HEAD`, tracked/untracked dirty counts, and a `git diff HEAD --binary` digest. Handle unborn/broken copied worktrees separately.
4. Do not infer that an old dirty patch is merged merely because the current branch advanced. Compare normalized origin identity, source/current history, patch hash, untracked paths/content, and test-apply the patch in a disposable clone/worktree.

## Recovery forms

- For a small named set: isolated recovery clone/check-out plus applied patch is readable and convenient.
- For a broad sweep: use compact per-source bundles containing `tracked.patch`, non-ignored untracked files, metadata, and hashes. This avoids cloning tens of stale repos and their dependency trees.
- For copied worktrees with invalid `.git` pointers or timeouts: create a raw working-tree tar excluding `.git` and dependency/cache directories, then hash it. Never silently omit it.
- Preserve secret-shaped files (`.env*`, service-account paths) as retain-but-isolate; do not print their contents or classify them as disposable solely because the code is old.

## Triage decisions

Use explicit evidence-backed categories:

- `ALREADY_PRESENT`: active repo has same origin plus same patch and untracked material.
- `LIKELY_SUPERSEDED`: only when history and content evidence support it; source age alone is insufficient.
- `APPLY_CANDIDATE`: patch cleanly applies or passes a 3-way check only in a disposable clone; this is not a merge recommendation.
- `CONFLICTS_WITH_CURRENT`: preserve as reference and port intent manually if desired.
- `REVIEW_FOR_CONTENT` / `ARCHIVE_ONLY`: no reliable active destination or primarily coursework/docs/IDE/generated state.

For an important active project, trace actual ingestion, storage, analytics, jobs, APIs, UI, privacy/retention, and tests before deciding archive versus current is better. A reverse-patch check is strong evidence that an archived feature already landed.

## Cleanup lifecycle

1. Delete only explicitly approved recovery artifacts first; never conflate them with original NAS source trees or active repositories.
2. Before deletion, resolve every target and assert it is below the approved recovery root; assert live target repositories still exist.
3. When the user wants a repositories-only recovery directory, retain only actual `.git` repository directories. Remove bundle trees, patches, raw tars, manifests, receipts, and generated reports; do not leave a new cleanup manifest if they explicitly ask for manifests to disappear.
4. Verify retained repositories have valid `.git` directories and report the exact retained paths plus final storage size.
