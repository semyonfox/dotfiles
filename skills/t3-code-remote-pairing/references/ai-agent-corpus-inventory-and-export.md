# AI agent corpus inventory and export notes

Use this when Semyon asks what training data exists in local AI-agent state directories (`~/.t3`, `~/.codex`, `~/.hermes`, `~/.claude`, opencode, Gemini/Antigravity, Cursor, Copilot) or wants to preserve/export it for personal model training.

## First principle

Do read-only inventory first. Do not mutate SQLite state or “undelete” rows just to count data. Open SQLite with `file:<path>?mode=ro`, run `PRAGMA quick_check`, and preserve tombstone columns such as `deleted_at` / `archived_at` as metadata rather than filtering them out.

## High-value local sources seen on Semyon's server

- `~/.t3/userdata/state.sqlite` — richest T3 Code corpus. Useful tables include `projection_projects`, `projection_threads`, `projection_thread_messages`, `projection_thread_activities`, `projection_turns`, and `orchestration_events`. Deleted T3 threads/projects are soft-deleted via `deleted_at`; rows and payloads usually remain valuable for training.
- `~/.codex/sessions/**/*.jsonl` plus `~/.codex/state_*.sqlite`, `logs_*.sqlite`, `memories_*.sqlite` — structured rollout/event traces, tracked threads, logs, spawn edges, memories/jobs. Check current DBs, not malformed old repair backups.
- `~/.hermes/state.db` — Hermes sessions/messages/tool outputs/subagent/cron/Discord/WhatsApp history. Use `sessions`, `messages`, and FTS mirrors only for search; do not double-count FTS content as separate training messages.
- `~/.claude/projects/**/*.jsonl` — Claude Code project conversations, attachments, title/skill injection/file snapshot records.
- `~/.local/share/opencode/opencode.db` and `~/.local/share/opencode/storage/{session,message,part}` — small but clean session/message/part data.
- `~/.gemini/antigravity-cli/conversations/*.db` — Antigravity/Gemini trajectory DBs with `steps`, `gen_metadata`, and trajectory metadata.
- Cursor/Copilot dirs are lower priority unless a deeper pass confirms chat-bearing SQLite/JSON state.

## Normalized export shape

A useful first-pass JSONL record should keep enough metadata to support dedupe and filtering later:

```json
{
  "source": "t3|codex|hermes|claude|opencode|gemini",
  "source_path": "...",
  "project_path": "...",
  "project_title": "...",
  "session_or_thread_id": "...",
  "thread_title": "...",
  "message_or_event_id": "...",
  "role": "user|assistant|tool|system|event|unknown",
  "timestamp": "...",
  "deleted_at": null,
  "archived_at": null,
  "content": "...",
  "metadata": {}
}
```

Keep raw IDs and timestamps. Do not collapse tool/event traces too early; for agent-training, tool failure/retry/verification traces are often the valuable part.

## Dedupe cautions

- T3 projections and `orchestration_events` overlap. Pick a canonical surface per export mode, or tag event rows separately.
- Hermes FTS tables mirror `messages`; never train on both.
- Codex backups such as `~/.codex-merge-backup` may duplicate current `~/.codex/sessions` rollouts; use path + session id + content hash.
- opencode DB rows and `storage/*.json` can mirror each other.

## Redaction/safety

Before any model-training export that leaves the machine, run a redaction pass for API keys, OAuth tokens, SSH material, Cloudflare/tunnel secrets, bearer tokens, database credentials, phone/email where not needed, and private identity context. For purely local personal training, still preserve a redacted derived export and keep raw state untouched as archive.

## Read-only probe pattern

Use or adapt `scripts/ai-agent-corpus-inventory.py` in this skill. It walks known AI-agent directories, records size/file/extension stats, counts JSONL lines and SQLite tables read-only, and prints a compact overview without changing the source stores.
