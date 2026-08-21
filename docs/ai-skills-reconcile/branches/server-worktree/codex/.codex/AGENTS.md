# Personal Codex defaults

For device fleet, SSH, Tailscale, NAS, router, PC, laptop, phones, T3 Code remote environments, or home-network maintenance, use the `device-fleet` skill. Keep inventory in `~/.codex/skills/device-fleet/references/computers.md`; never store secrets or sudo passwords.

## working agreement

- inspect before editing and verify before claiming success
- preserve unrelated work; use a branch or independent worktree when writes overlap
- answer, diagnose, review, and plan without implementing unless change is requested
- for change requests, make the smallest sufficient local change and run relevant safe checks
- stop at the requested phase; do not expand into unrelated cleanup, migrations, dependencies, or configuration
- after one failed hypothesis, re-check it against observed evidence before inventing a workaround
- never mention AI, Codex, Claude, or co-authorship in commits

## model routing

Before orchestrating or delegating agents, assigning a decision owner or implementer, escalating effort, requesting cross-model review, or choosing among Codex and Claude models, use the `model-routing` skill. Its current scoring and orchestration matrices are the source of truth; default to Terra medium for routine coding.

## delivery

Use the `ship-changes` skill before the first commit, push, PR, CI-repair, ready-for-review, or merge action. Delivery must use a scoped branch and PR, preferring an existing base in this order: `dev`, `develop`, `testing`, `staging`, `main`, `master`, then the remote default. An explicitly named base wins.

- small, clearly safe changes may merge after proportional validation and required checks pass
- riskier bounded changes may merge only after broader relevant tests, all required checks green, mergeability confirmed, and final diff review
- large features and high-risk changes remain draft PRs unless the user explicitly asks to merge

## visual evidence

Use `visual-evidence` only for slide decks, SVG/vector compositions, complex infographics, or production visual-reference QA. Do not use `agy` for generic visuals or ordinary frontend work.
