# Retiring Markdown/editor spike branches

Use when Semyon decides old Oghma Markdown/editor worktrees or spike branches are no longer part of the chosen direction.

## Pattern

1. Confirm the product/architecture decision first, usually from the handover doc or session history:
   - current direction: CodeMirror-backed single Markdown write surface;
   - Shiki is renderer/code-block polish, not editor replacement;
   - MDXEditor/Milkdown spikes are inactive unless explicitly revived.
2. Before deleting branches, mine the spike docs/diffs for durable evaluation data worth preserving:
   - `docs/spikes/*.md` verdicts;
   - measured bundle/chunk sizes;
   - build/lint/test/smoke results;
   - security or SSR/client-only caveats;
   - explicit `VALIDATED` / `PARTIAL` / `INVALIDATED` verdicts.
3. Search only the snapshot diff or spike docs for perf artifacts; avoid broad repo grep that drowns in unrelated historical docs:

```bash
for b in agent/md-codeblock-ux agent/md-mdxeditor-spike agent/md-milkdown-spike agent/md-renderer-consolidation agent/md-shiki-renderer; do
  echo "=== $b changed files ==="
  git diff-tree --no-commit-id --name-only -r "origin/$b"
  echo "--- perf-ish hits in snapshot diff ---"
  git diff "origin/$b^" "origin/$b" -- . ':!package-lock.json' \
    | grep -i -E 'unlighthouse|lighthouse|performance|perf|web[- ]?vitals|bundle|benchmark|lcp|cls|inp|tti' || true
  echo
 done
```

4. If keeping a handover doc, keep it aligned with reality:
   - if branches are preserved, list them explicitly as snapshots;
   - if Semyon chooses deletion, remove the branch table and keep only the durable decision/rationale.
5. Delete obsolete branches only after explicit approval:

```bash
for b in agent/md-codeblock-ux agent/md-mdxeditor-spike agent/md-milkdown-spike agent/md-renderer-consolidation agent/md-shiki-renderer; do
  git ls-remote --heads origin "$b"
  git push origin --delete "$b"
  git branch -D "$b" 2>/dev/null || true
 done
git fetch --prune origin
```

6. Verify deletion:

```bash
for b in agent/md-codeblock-ux agent/md-mdxeditor-spike agent/md-milkdown-spike agent/md-renderer-consolidation agent/md-shiki-renderer; do
  git ls-remote --heads origin "$b"
 done
git branch --list 'agent/md-*'
git worktree list --porcelain
```

## Session-specific finding worth remembering

The Milkdown spike had the only concrete perf/bundle numbers in its `docs/spikes/milkdown-editor-spike.md`:

- `node_modules/@milkdown` footprint: about 14 MB.
- Milkdown client chunk: `948,636` bytes raw / `291,690` bytes gzip.
- Tiny companion chunk: `856` bytes raw / `547` bytes gzip.

The MDXEditor spike had qualitative bundle warnings but no numeric Lighthouse/Unlighthouse report. No Lighthouse/Unlighthouse artifacts were present in those old markdown spike snapshots.
