# Skill review queue

These are source snapshots for personal review. They are not canonical shared skills.

Do not promote these folders into `skills/` until each one has been reviewed, renamed where appropriate, and given portable metadata.

## Snapshot sources

- `mattpocock/` comes from `mattpocock/skills`, refreshed to `5863806dd4e15c63174bee4e7515a4256792ecfa` (2026-11-12).
- `pstack/` comes from `cursor/plugins` at `e1cc03121a0e71129a4fb730d7c5528a0a3e43c8` (2026-11-16), under its `pstack/` plugin. Only `LICENSE` remains here, for the promoted skills.
- `tstack/` comes from `t3dotgg/tstack` at `7de017b3fc9d50c03cf3ecb98fb71e0ca65a78bd` (2026-10-24), with its `skills/` folders flattened into `tstack/`. Checked against `11e37a74d0a6868c121cd0910ab2b3bd9873b92a` (2026-11-11) on 2026-11-17: the `council` changes are merged, and `full-stop`'s looser trigger was declined so a closing "full stop" used as emphasis doesn't start PR work.
- All three sources are MIT-licensed. Their licence texts stay here for the promoted skills.

## Review status

Triaged on 2026-11-12. Snapshots refreshed and fully decided on 2026-11-17. Dropped snapshots stay in git history and upstream.

### Left to decide

Nothing. Every snapshot was decided on 2026-11-17.

### Promoted

- 2026-11-17: `pstack/blast-radius`, `typescript-best-practices` and `correct` moved to `skills/` with local edits. `grilling` and `unslop` took upstream additions. `why` became a line in `skills/AGENTS.md`. `tstack/leaving-pr-comments` was promoted with upstream wording, its banner limited to `attribution: on` repos. It now holds the comment rules that used to sit in `babysit-pr`.

### Dropped

- Cloudflare bundle (`agents-sdk`, `cloudflare*`, `durable-objects`, `sandbox-stable`, `turnstile-spin`, `workers-best-practices`, `wrangler`): dropped on 2026-11-17 with its opencode, Cursor and Gemini links. Hermes' loose copies were moved to `~/.local/share/dropped-skills/hermes-cloudflare-20261117`. Upstream is `cloudflare/skills`.
- `mattpocock/wizard`: dropped on 2026-11-17, not needed.
- `pstack/benchmark-checklist`, `principle-explain-the-number`: dropped on 2026-11-17, not needed.
- 2026-11-17, all not needed: `pstack/principle-test-behavior-not-implementation` and `principle-attack-the-premise` (their ideas live on as `skills/AGENTS.md` lines), `ketchup`, `ketchup-video`, `create-formal-verification-skill`, `maintain-formal-verification-skill`, `statechart`, `sharpen`, `in-your-own-words`, `make-bot-ui`, `poteto-help`. Never imported and declined: `mattpocock/retro`, `pr`, `chief-of-staff`, `software-factory`, and pstack's `reflect`, `interrogate`, `arena`, `swarm`, `tdd`, `technical-writing`, `recall`, `automate-me`, `teach`, `bro`, `poteto-mode`, `setup-pstack`, `show-me-your-work`, `create-verification-skill` and the other principle skills.
- `pstack/how`: spawns a subagent unasked and adds little over reading the code.
- `mattpocock/setup-matt-pocock-skills`, `to-tickets`, `triage`, `wayfinder`: issue-tracker workflows. Hermes' board is the task list.
- `mattpocock/teach`, `pstack/teach-codebase`: `study` covers teaching.
- `mattpocock/handoff`, `resolving-merge-conflicts`, `wait-what`, `tdd`, `to-questionnaire`: too thin or covered by the harness and global guidance.
- `pstack/no-comments`, `figure-it-out`, `architect`: spawn agents unasked or depend on skills that aren't here. Global guidance already sets the comment style.
- `web-perf--gemini-snapshot`: outdated copy of `web-perf`.
