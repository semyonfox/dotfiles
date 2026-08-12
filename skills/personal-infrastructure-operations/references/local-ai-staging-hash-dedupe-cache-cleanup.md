# Local AI staging hash dedupe + conservative cache cleanup

Use when Semyon asks to tidy recovered/yoinked AI-agent state directories such as `~/ai-yoink-run-*`, `~/ai-staging`, device-import staging trees, or similar local rescue/staging artifacts.

## Scope and safety rules

- Treat canonical AI/runtime state as source-of-truth and read-only unless Semyon explicitly says otherwise:
  - `~/.t3`, `~/.t3-code*`, `~/.hermes`, `~/.claude`, `~/.codex`, `~/.config` app state.
- Delete or move files only inside the explicitly approved staging/yoink roots.
- Do not touch project worktrees during disk cleanup unless Semyon explicitly says to. He may be actively working across many worktrees and will cut them back later.
- Use file content hashes, not names, mtimes, or paths. These staging sets often contain the same content under different recovered path names.
- Do not follow symlinks; stay on the local filesystem; preserve enough manifest evidence to reverse/check decisions.

## Recommended workflow

1. Capture before state:

```bash
df -hT /
du -sh ~/ai-yoink-run-* ~/ai-staging 2>/dev/null
```

2. Hash every regular file recursively in the approved staging roots with SHA-256. Record at least: root, relative path, size, sha256, and any read errors.

3. Dedupe staging roots against each other first:

- group by `(sha256, size)`;
- keep one copy, preferentially in the chosen primary staging tree;
- delete or quarantine only duplicates inside the approved staging roots;
- never delete from canonical source trees.

4. Then compare remaining staging files against canonical AI/source state hashes:

```text
~/.claude
~/.codex
~/.hermes
~/.t3
~/.t3-code*
~/.config/<relevant app dirs>
```

If a staging file's content already exists in source state, remove/quarantine the staging copy only.

5. For consolidation after dedupe:

- re-hash both staging roots and verify zero remaining duplicate content groups before moving;
- move unique secondary-root files under a clear subdirectory of the primary root, for example:
  `~/ai-yoink-run-YYYYMMDD-HHMMSS/consolidated-ai-staging-YYYYMMDD/`;
- preserve relative paths;
- if the target relative path exists with different content, keep both using a collision suffix and record it;
- leave the old secondary root as a tiny README/pointer rather than silently deleting the directory.

6. Manifest requirements:

Create a timestamped manifest directory such as `~/ai-consolidate-YYYYMMDD-HHMMSS/` or `~/ai-dedup-YYYYMMDD-HHMMSS/` containing:

```text
summary.json
all_file_hashes.csv
duplicate_groups.json or remaining_duplicate_groups_before_consolidation.json
deleted_files.csv or quarantined_duplicate_files.csv
moved_files.csv
collision_preserved.csv
```

The summary should include before/after `du`, file counts, deleted/quarantined/moved counts, duplicate group count, and safety booleans: symlinks not followed, system dirs not modified, worktrees not touched.

## Cache cleanup in the same disk-pressure session

Safe rebuildable cache candidates, when Semyon approves cache cleanup:

- `docker builder prune --force` for build cache, not volumes/databases.
- `npm cache clean --force`; remove stale `_npx` content if needed.
- `pnpm store prune` rather than deleting the whole pnpm store by default.
- `pip cache purge`.
- Gradle caches (`~/.gradle/caches`) only after checking no Gradle daemon/build is active.
- Browser/model caches that are clearly caches and not app state: Puppeteer, Playwright, HuggingFace cache, datalab model cache.
- Conservative `/tmp` cache directories only.

Do not clean: Docker volumes/databases, `/mnt/media`, `~/.t3`, `~/.hermes`, `~/.claude`, `~/.codex`, or active worktrees.

## Journald cleanup

If Semyon provides sudo approval/password for journal cleanup, use it only for the scoped journal command. Prefer a bounded vacuum:

```bash
sudo journalctl --vacuum-size=512M
journalctl --disk-usage
```

If stdin password piping is blocked, run sudo in a PTY and submit the password interactively; do not encode the password in files or scripts.

## Reporting

Lead with actual result: final `df`, final sizes, manifest path, duplicate groups, files moved/deleted/quarantined, and exact safety scope. Keep the report short; Semyon mainly wants evidence and what is now safe to remove next.
