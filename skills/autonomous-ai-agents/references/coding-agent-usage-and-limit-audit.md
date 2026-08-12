# Coding Agent Usage and Limit Audit

Use this reference when Semyon asks to check usage, spend, active blocks, auth, or limits for Claude Code and Codex.

## Preferred Commands

Use `bunx ccusage` even when `ccusage` is not installed globally. Do not stop at `command not found`; `bunx` can fetch and run it directly.

```bash
bunx ccusage claude blocks --active --timezone Europe/Dublin
bunx ccusage claude daily --since YYYY-MM-DD --timezone Europe/Dublin --json
bunx ccusage claude blocks --recent --timezone Europe/Dublin --json
bunx ccusage codex daily --since YYYY-MM-DD --timezone Europe/Dublin --json
bunx ccusage codex monthly --timezone Europe/Dublin --json
```

For readiness and account state:

```bash
codex login status
codex doctor
claude --version
claude auth status
```

## Reporting Shape

Report the concrete numbers that matter first:

- Claude auth/subscription, active block status, recent total tokens/cost, today's tokens/cost, models used.
- Codex auth/connectivity, recent total tokens/cost, current month tokens/cost, any current-day gap in ccusage, and model mix if useful.
- Limit visibility separately from usage: Claude Code may expose subscription/auth but `/status` can be unavailable in noninteractive mode; Codex CLI may expose login and health without remaining quota.

Do not imply the remaining quota was checked unless the CLI actually exposed it. Say clearly when only usage/auth/health were available.

## Pitfalls

- `ccusage` may be absent from PATH while `bunx ccusage ...` works. Treat that as the normal path, not a blocker.
- `ccusage codex daily` table output can truncate dates in narrow terminals. Use `--json` for exact dates and totals.
- `claude --print` does not necessarily support slash commands like `/status`; use `claude auth status` for account state and `ccusage claude blocks --active` for active session blocks.
- `codex debug models` returns a very large JSON catalog and can flood output; avoid it unless model catalog details are explicitly needed.
