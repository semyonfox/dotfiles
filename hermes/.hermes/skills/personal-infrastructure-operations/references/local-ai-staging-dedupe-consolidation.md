# Local AI staging dedupe and consolidation

Use when Semyon asks to tidy recovered AI-agent state dumps such as `ai-yoink-*`, `ai-staging`, copied `.claude`/`.codex`/`.t3`/T3Code state, or similar local archive trees.

## Core workflow

1. **Scope deletes to the staging/archive trees only.** Treat live system state as read-only comparison sources:
   - `~/.claude`
   - `~/.codex`
   - `~/.hermes`
   - `~/.t3`
   - `~/.t3-code*`
   - `~/.config` subtrees that are explicitly relevant
2. **Hash by file content, recursively.** Use SHA-256 or another strong content hash. Do not rely on names, paths, mtimes, or sizes alone; these dumps often contain the same files under different host/path prefixes.
3. **Do not follow symlinks.** Preserve symlink metadata or ignore symlink targets; never let a staging cleanup wander into live home directories.
4. **Stay on the intended filesystem/root.** Avoid crossing mounts such as `/mnt/media` unless explicitly asked.
5. **Dedupe in phases:**
   - staging tree vs staging tree: keep one copy, remove only duplicates inside the approved staging/yoink roots.
   - remaining staging files vs live AI/system roots: delete/move only the duplicate copy in staging/yoink, never the live source.
6. **Write manifests before and after mutation.** Include:
   - full file hash CSV
   - duplicate group JSON/CSV
   - deleted/moved file list
   - before/after `du` sizes
   - safety assertions: allowed roots, symlinks not followed, live roots not modified
7. **Prefer quarantine/move over delete while reshaping layout.** Once deduped, consolidation/flattening should move files into one clean location and only delete empty stubs after verification.
8. **Flatten cleanly; do not create surprising nested archive roots.** If `ai-staging` is consolidated into `ai-yoink-*`, move its unique files into the chosen root while preserving relative path structure, not into a permanent `consolidated-*` subfolder unless Semyon explicitly wants that.
9. **Handle path conflicts conservatively.** If the destination path exists with the same hash, remove/move the duplicate. If it exists with different content, preserve both with a collision suffix and record it in the manifest.
10. **Additive-only merge means no interpretation-heavy surgery.** Only merge obvious append/log/JSONL/text content when it is truly additive and non-conflicting. Otherwise leave files separate and report candidates.

## Worktree guardrail

When Semyon says active work is in progress or says not to touch worktrees, exclude worktrees and project build trees from cleanup even if they are large. Report them as known pressure only; do not prune, flatten, or delete them.

## Useful verification commands

```bash
df -hT /
du -sh /home/semyon/ai-yoink-* /home/semyon/ai-staging 2>/dev/null || true
find /home/semyon/ai-staging -xdev -type f | wc -l
find /home/semyon/ai-yoink-run-*/ -xdev -type f | wc -l
```

Use scripts for the actual hash walk when the tree is large; a Python script with `os.walk(..., followlinks=False)`, `Path.is_symlink()` checks, chunked SHA-256 reads, and CSV/JSON manifests is safer than ad-hoc shell one-liners.

## Sudo/journald note

If Semyon gives a sudo password for a narrowly scoped cleanup such as journald vacuuming, do not pipe the password into `sudo -S`; Hermes blocks that pattern. Start the sudo command in a PTY/background process, wait for the interactive password prompt, submit the password to that process, then verify with `journalctl --disk-usage` and `df -hT /`. Keep the sudo action scoped to the command the user approved.
