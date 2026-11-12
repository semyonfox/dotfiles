# Skill review queue

These are source snapshots for personal review. They are not canonical shared skills.

Do not promote these folders into `skills/` until each one has been reviewed, renamed where appropriate, and given portable metadata.

Exception: the cloudflare bundle below is temporarily linked into opencode, Cursor, and Gemini runtimes (2026-08-25) so loose per-provider copies could be deduplicated. Repoint or drop those links once the skills are reviewed and promoted.

## Snapshot sources

- `mattpocock/` comes from `mattpocock/skills` at `5b15a47f2d7150f545fbcacbfe381787fc0230dc`.
- `pstack/` comes from `cursor/plugins` at `46125561306434d8a1d7745d540d8932ab0cd2a2`, under its `pstack/` plugin.
- `tstack/` comes from `t3dotgg/tstack` at `7de017b3fc9d50c03cf3ecb98fb71e0ca65a78bd` (2026-10-24), with its `skills/` folders flattened into `tstack/`.
- All three source snapshots are MIT-licensed. Their license texts are retained beside the imported folders.
- The top-level `agents-sdk`, `cloudflare*`, `durable-objects`, `sandbox-sdk`, `turnstile-spin`, `workers-best-practices`, and `wrangler` folders come from identical loose copies found in `~/.config/opencode/skills`, `~/.cursor/skills`, `~/.gemini/skills`, and `~/.hermes/skills` (opencode's copy kept as the snapshot). Vendor Cloudflare skill bundle, unreviewed.

## Review status

Triaged on 2026-11-12. Dropped snapshots stay in git history and upstream.

### Left to decide

| Skill | Verdict |
| --- | --- |
| `pstack/blast-radius` | Promote candidate. Fits the cross-review step in `repo-audit` |
| `pstack/how`, `pstack/why` | Promote candidates. Their critic model lists are stale and must use the global Models table |
| `pstack/typescript-best-practices` | Promote candidate. Its rules match global guidance but it depends on principle skills that don't exist here |
| `mattpocock/wizard` | Promote candidate for homelab steps only Semyon can do, such as credentials |
| Cloudflare bundle | Live in opencode, Cursor and Gemini. Replace with the upstream Cloudflare skills or promote, then repoint those links |

### Dropped

- `mattpocock/setup-matt-pocock-skills`, `to-tickets`, `triage`, `wayfinder`: issue-tracker workflows. Hermes' board is the task list.
- `mattpocock/teach`, `pstack/teach-codebase`: `study` covers teaching.
- `mattpocock/handoff`, `resolving-merge-conflicts`, `wait-what`, `tdd`, `to-questionnaire`: too thin or covered by the harness and global guidance.
- `pstack/no-comments`, `figure-it-out`, `architect`: spawn agents unasked or depend on skills that aren't here. Global guidance already sets the comment style.
- `tstack/leaving-pr-comments`: its banner is model attribution and its writing rules live in `babysit-pr`. `tstack/LICENSE` stays for the promoted tstack skills.
- `web-perf--gemini-snapshot`: outdated copy of `web-perf`.
