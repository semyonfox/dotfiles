# e18e dependency hygiene sweeps

Use this when Semyon asks to run e18e / `@e18e/cli` across many projects to see dependency/native-feature opportunities.

## Safe default

Run **analyze only** first. Do not run `migrate`, `migrate --all`, or broad codemods across multiple repos without an explicit per-project approval.

Recommended command per project:

```bash
npx -y @e18e/cli@0.7.0 analyze "$repo" --json --log-level error --report-level info
```

Rationale:

- `analyze` reads `package.json` + lockfile and reports dependency replacements, duplicate dependencies, publint packaging issues, and web/native feature opportunities.
- `migrate` rewrites files. Even with `--dry-run`, it still walks source files and runs codemod transforms; review it in a clean git worktree before applying.
- `publint` packing uses ignore-scripts in current versions, so analyze is low-risk but can still be slow/noisy.

## Project discovery filter

For all-project sweeps, find JS/TS repos with `package.json` plus one of:

- `pnpm-lock.yaml`
- `package-lock.json`
- `yarn.lock`
- `bun.lock` / `bun.lockb`

Exclude dependency/build/generated/archive areas before running tools:

- `node_modules`, `.git`, `.cache`, `.next`, `dist`, `build`, `coverage`, `target`, `.turbo`, `.expo`
- worktrees/clones unless explicitly relevant: `/.worktrees/`, `/.claude/worktrees/`
- device/archive/session dumps: `/_device-archive/`, `/ai-analysis/`, raw imported dumps
- examples/coursework/templates/reference repos unless the user explicitly asks for them

For Semyon specifically, prefer canonical active repos over duplicates. For OghmaNotes, canonical checkout is `~/code/university/ct216-software-eng/oghmanotes`.

## Report shape

Produce both raw JSON and a short Markdown summary under `~/.hermes/reports/e18e-sweep-<timestamp>/`:

- `projects.json` — discovered projects and lockfiles
- one JSON file per project — raw e18e output
- `summary.json` — status/counts/report paths
- `relevant-report.md` — filtered human report

In the chat summary, include:

- exact command used
- number of relevant projects
- top noisy projects by finding count
- top module replacement candidates
- top native/web-feature suggestions
- specific notes for priority repos such as OghmaNotes/swim
- reminder that no `migrate` was run

## Interpreting findings

Treat e18e output as triage, not a todo list.

High-signal:

- direct dependency replacements like `uuid` → `crypto.randomUUID` when runtime support is clear
- small native syntax replacements in owned source files
- packaging warnings for actual npm packages

Needs care:

- auth/security replacements such as `jsonwebtoken`; preserve semantics and tests
- `axios` → `fetch` in code with interceptors, cancellation, retries, uploads, or custom error handling
- duplicate transitive deps in large lockfiles; often resolved by normal dependency upgrades rather than manual edits

Usually noise:

- vendored/minified bundles under `public/assets/vendor`
- generated workers such as `pdf.worker.js`
- build outputs if the scan includes them

## Verification

After an analyze-only sweep:

- confirm report files exist
- optionally snapshot `git status --porcelain` for relevant repos, but report pre-existing dirt without implying e18e caused it
- do not claim project files were untouched unless the command path truly avoided writes; better: “No migrate/codemod writes were run.”

For any follow-up migration, use a clean branch/worktree, run a narrow migration or hand edit, inspect the diff, then run that project’s tests/build.