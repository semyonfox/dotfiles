# Local AI usage dashboard audits

Use when Semyon asks to inspect or improve local AI usage/spend dashboards built from Claude/Codex/Gemini/Cursor/OpenCode session files, especially ccusage/CodeBurn/CCDeck-style tools.

## Workflow

1. **Locate both the tool and the data artifact.** Search for the dashboard project and any exported aggregate files such as `ai_usage.json`. Treat an aggregate JSON and a live provider scan as two different data sources.
2. **Run the dashboard from the intended root, then export JSON.** Prefer a machine-readable report (`report --format json -p all` or equivalent) and save it to a stable explicit path when the user may reuse it. `/tmp/...` is fine for quick scratch only; mention it is ephemeral.
3. **Compare live scan totals against known aggregate exports.** Compute total cost/tokens by day and by model/source from both data sets. Large deltas usually reveal missing session roots rather than pricing mistakes.
4. **Break down missing spend by provider/model/date.** In the CCDeck case, a large delta between `/home/semyon/ai_usage.json` and the root live scan was almost entirely Codex/GPT-5.5 data, while Claude matched closely.
5. **Inspect provider discovery roots.** Running from `$HOME` does not mean the tool recursively scans every archived dump under `$HOME`; many tools default to live roots like `~/.codex`, `~/.claude`, or `~/.config/...`. Archived corpora under project folders such as `code/personal/ai-analysis/sessions/` and `raw-sessions-by-device/` often need explicit env vars / multi-dir configuration.
6. **Audit path normalization separately from totals.** Totals can be useful while project attribution is wrong. Look for duplicate display names with different paths, mixed `\` and `/`, Windows paths (`C:\Users\...`) separated from Linux equivalents, WSL-ish `/c/Users/...`, and worktree paths that should roll up to the canonical repo.
7. **Prefer path over display name until normalization is fixed.** Sluggy names like `-home-semyon` or `-home-semyon-code-personal-swim` may be lossy and duplicate-prone.
8. **Check skipped parser warnings.** A malformed/skipped transcript may matter, but quantify the provider total before chasing it. In the CCDeck session, a skipped Cursor-agent file was not the main missing spend.
9. **Keep the repo clean after running build/report commands.** Some builds refresh bundled pricing snapshots; if that was incidental, revert generated snapshot changes before reporting.

## Durable implementation notes

- Add a canonical path normalizer before trusting project breakdowns. It should map equivalents like:
  - `C:\Users\foxsc\code\personal\swim`
  - `/c/Users/foxsc/code/personal/swim`
  - `/home/semyon/code\personal\swim`
  - `/home/semyon/code/personal/swim`
  to one canonical project key, usually `/home/semyon/code/personal/swim` on Linux.
- Normalize path separators before grouping keys, but do not blindly fabricate paths from lossy slugs.
- Roll up ephemeral worktrees such as `~/.t3/worktrees/<repo>/...` and `code/.worktrees/<repo>/...` to the canonical repository when possible.
- Support explicit multi-root discovery for archived provider data; do not assume `$HOME` scans historical dumps.

## Reporting pattern

Keep the user-facing report short and concrete:

- where the report file was written and whether it is ephemeral
- aggregate totals and the delta vs any known export
- which provider/model accounts for missing spend
- whether project attribution is trustworthy
- exact examples of bad path grouping
- one or two recommended fixes
