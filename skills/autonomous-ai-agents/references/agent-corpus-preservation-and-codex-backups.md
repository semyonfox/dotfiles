# Agent corpus preservation and Codex/T3 backup triage

Use this reference when Semyon asks whether AI-agent data can be deleted, merged, exported, or used for training. The recurring pattern is: inspect read-only, distinguish active runtime state from corpus/archive state, and avoid destructive merges into live agent stores.

## High-value local stores seen in this environment

Common paths worth inventorying before deleting anything:

- `~/.t3/userdata/state.sqlite` — T3 Code projects/threads/messages/activities/events. T3 uses soft deletes (`deleted_at`), so deleted threads/projects can still contain valuable training data.
- `~/.codex/sessions/**/*.jsonl` — Codex rollout event streams.
- `~/.codex/state_*.sqlite` — Codex thread index/metadata; useful but not a complete source of truth for all session files.
- `~/.codex/logs_*.sqlite` — Codex logs/usage-ish rows; verify integrity before relying on old backups.
- `~/.codex-merge-backup/*` — rollback/forensics backups from prior Codex session merges; do not assume duplicates.
- `~/.hermes/state.db` — Hermes sessions/messages/tool outputs/subagent traces. FTS mirror tables duplicate `messages`; do not export both as primary content.
- `~/.claude/projects/**/*.jsonl` — Claude Code project conversations.
- `~/.local/share/opencode` — OpenCode DB plus storage JSON for sessions/messages/parts.
- `~/.gemini/antigravity-cli/conversations/*.db` — Antigravity/Gemini trajectory DBs.

## Read-only inventory checklist

1. **Do not mutate first.** Open SQLite with `mode=ro`; parse JSONL without rewriting.
2. **Measure size and shape:** bytes, file counts, JSONL counts, DB table counts, parse errors.
3. **For SQLite:** run `PRAGMA quick_check` or `integrity_check`; then count high-value tables.
4. **For JSONL:** count lines, event `type`s, top-level/payload keys, parse errors, and representative examples.
5. **For backups:** compare by content hash, relative path, line containment, and semantic keys — not just filenames.
6. **Separate runtime safety from training value.** A file can be unsafe to merge into a live app but still valuable in an offline corpus.

## Codex merge-backup lesson

A `~/.codex-merge-backup/<stamp>/replaced-root/**/*.jsonl` tree can contain old versions of rollout files that were replaced during a merge. In the observed case:

- all 178 backup JSONLs had matching paths in `~/.codex/sessions`
- none had identical size/hash
- current files were generally larger/newer
- backup still had thousands of unique old JSONL records
- differences were often Linux-vs-Windows path normalization (`/home/semyon` vs `C:\\Users\\foxsc`), but not only that
- only a subset of files had matching rows in `~/.codex/state_*.sqlite`, so file parsing is required for corpus work

Conclusion: do **not** delete or live-merge such a backup until a normalized corpus export/archive has verified coverage of backup-only events.

## Safe no-loss strategy

Prefer a **corpus merge**, not a runtime merge:

- Keep live stores (`~/.codex/sessions`, `~/.codex/state_*.sqlite`, `~/.t3/userdata/state.sqlite`) untouched unless the user explicitly asks for app repair.
- Export current and backup variants to a separate root such as `~/ai-corpus/codex/`.
- Preserve provenance on every event: source, variant, backup stamp, rollout relative path, line number, timestamp, event type, session/thread ID, raw hash, semantic key, and whether it came from backup.
- Dedupe in the corpus layer with tiers:
  1. exact raw-line SHA-256
  2. stable event key (`session_id + type + payload.call_id`, `turn_id`, role/timestamp, etc.)
  3. normalized semantic hash after replacing machine paths with `$HOME` and normalizing slashes
- If two events share a stable key but differ beyond path normalization, keep both as variants and mark a conflict instead of overwriting one.

## What not to do

- Do not append backup-only lines directly into active `~/.codex/sessions/**/*.jsonl` files.
- Do not put archival copies under active discovery paths unless you know the agent indexer will ignore them.
- Do not treat `deleted_at` rows in T3 as trash; they may still have messages, turns, activities, and events.
- Do not use FTS mirror tables as separate primary content during export.
- Do not declare a backup deletable because filenames exist in the current store; prove content or corpus coverage.

## Deletion gate

A backup becomes safely deletable only after all are true:

- immutable archive/tarball exists or the normalized corpus intentionally supersedes it
- SHA-256 manifest recorded for raw source files
- exporter includes backup-only events and conflict variants
- validation report shows parse errors, duplicate counts, conflict counts, and coverage
- restore/read test succeeds
- user explicitly approves deletion
