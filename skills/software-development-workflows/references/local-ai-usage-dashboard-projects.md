# Local AI usage dashboard project inspection

Use when Semyon asks whether he has a local project for AI/agent usage analysis, spend dashboards, `ccusage`/CodeBurn-style reports, or wants details from an `ai_usage.json` export.

## Recon pattern

1. Search for both data exports and project roots:
   - file names: `ai_usage.json`, `*usage*`, `*ai*usage*`
   - code terms: `totalCost`, `cacheReadTokens`, `modelBreakdowns`, `usage dashboard`, notable model names from the export
   - likely roots: `~/code/personal`, `~/security-cleanup/*`, staging mirrors only as secondary evidence
2. Distinguish the raw export from the project:
   - `ai_usage.json` is data.
   - a repo/package with `package.json`, README, provider parsers, tests, dashboard/CLI files is the artifact to inspect.
3. Check provenance and cleanliness before running anything:
   - `git status --short --branch`
   - `git remote -v`
   - read `package.json` and README for intent, supported commands, and provider scope.
4. Install deps in the way the project actually needs. If npm is configured with `omit=dev`, use `npm ci --include=dev` before builds/tests that need `tsx`, `tsup`, `vitest`, etc. Do not persist a rule that npm is broken; the durable lesson is to inspect npm omit/production config when dev binaries are missing after `npm ci`.
5. Verify the project with real commands:
   - build command from `package.json`
   - test command from `package.json`
   - run a representative CLI/report command against local data, preferably JSON output that can be summarized deterministically.
6. If a build/regeneration step touches bundled data snapshots such as pricing caches, restore them unless the user explicitly asked to update generated assets:
   - inspect `git status --short`
   - revert incidental generated-data churn before finalizing.

## Reporting shape

Keep the handoff short and concrete:

- path and remote
- what it is in one sentence
- commands it exposes
- verification results: build/test/report output
- top-line metrics from a live report: total cost, calls/sessions, cache hit, top days/models/sessions
- any remaining failure with exact scope, e.g. "one timeout test" rather than implying the app is broken

Avoid dumping the entire JSON export. The value is in surfacing the expensive days/models and whether the local project already provides the desired dashboard/reporting workflow.
