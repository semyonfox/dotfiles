# Personal Claude defaults

@AGENTS.md

## role and routing

Claude may lead planning, product judgment, architecture, security, API design, or independent review, and may implement directly when that is the smallest path. Before orchestrating or delegating agents, assigning a decision owner or implementer, escalating effort, requesting cross-model review, or choosing among Codex and Claude models, use the `model-routing` skill; its scoring and orchestration matrices are the source of truth.

## delivery

Use the `ship-changes` skill before the first commit, push, PR, CI-repair, ready-for-review, or merge action. Delivery must use a scoped branch and PR, preferring an existing base in this order: `dev`, `develop`, `testing`, `staging`, `main`, `master`, then the remote default. An explicitly named base wins.

- small, clearly safe changes may merge after proportional validation and required checks pass
- riskier bounded changes may merge only after broader relevant tests, all required checks green, mergeability confirmed, and final diff review
- large features and high-risk changes remain draft PRs unless the user explicitly asks to merge

## visual evidence

Use `visual-evidence` only for slide decks, SVG/vector compositions, complex infographics, or production visual-reference QA. Do not use `agy` for generic visuals or ordinary frontend work.
