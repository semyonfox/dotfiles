# Skill review queue

These are source snapshots for personal review. They are not canonical shared skills.

Do not promote these folders into `skills/` until each one has been reviewed, renamed where appropriate, and given portable metadata.

Exception: the cloudflare bundle below is temporarily linked into opencode, Cursor, and Gemini runtimes (2026-08-25) so loose per-provider copies could be deduplicated. Repoint or drop those links once the skills are reviewed and promoted.

## Snapshot sources

- `mattpocock/` comes from `mattpocock/skills` at `5b15a47f2d7150f545fbcacbfe381787fc0230dc`.
- `pstack/` comes from `cursor/plugins` at `46125561306434d8a1d7745d540d8932ab0cd2a2`, under its `pstack/` plugin.
- Both source snapshots are MIT-licensed. Their license texts are retained beside the imported folders.
- The top-level `agents-sdk`, `cloudflare*`, `durable-objects`, `sandbox-sdk`, `turnstile-spin`, `workers-best-practices`, and `wrangler` folders come from identical loose copies found in `~/.config/opencode/skills`, `~/.cursor/skills`, `~/.gemini/skills`, and `~/.hermes/skills` (opencode's copy kept as the snapshot). Vendor Cloudflare skill bundle, unreviewed.
- `web-perf--gemini-snapshot/` is an outdated copy of the fleet `web-perf` skill from `~/.gemini/skills`, differing only by a missing metadata block. Safe to delete after review.

## Review status

- The copied `SKILL.md` files and supporting files are upstream source, unchanged.
- `pstack/teach-codebase/` contains Pstack's upstream `teach` skill. The directory name records the intended final name only. Its internal name remains untouched until review.
- `setup-matt-pocock-skills`, `triage`, `to-tickets`, and `wayfinder` belong to one tracker-oriented set. Keep their setup dependency explicit while reviewing them.
- No provider metadata has been added yet.
