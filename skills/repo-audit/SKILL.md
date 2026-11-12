---
name: repo-audit
description: Use when the user asks for a full review, audit, review-and-fix pass, bake-off, or "review the whole repo" across several models. Runs blind reviews, a plan, an implementation, a cross-review and clean checks, then reports who found what.

metadata:
  harnesses: [claude, codex, opencode]
---

# Repo audit

A whole-repo review that ends in a fixed branch. Each step goes to the model that did it best in past runs (see [references/evidence.md](references/evidence.md)). For one diff, use `sol-loop` instead.

## Roles

| Step | Model | Effort |
| --- | --- | --- |
| 1. Blind review | `gpt-6.1-sol` and `claude-fable-5-2` in parallel | high |
| 2. Security review | `claude-opus-5-5` | high |
| 3. Merge plan | lead (`claude-opus-5-5`) | |
| 4. Implementation | `gpt-6.1-sol` | high |
| 5. Cross-review | `claude-fable-5-2` | high |
| 6. Fix and verify | lead | |

Never let a model cross-review its own implementation. If a model is missing from `orchestrator_capabilities`, say so and skip that slot rather than swapping in another.

## Workflow

1. **Scope.** Inspect the branch, worktree and existing changes. Record the base commit. Work on a local branch off it.
2. **Blind review.** Send both reviewers the same brief: repo path, base commit, what the product does, what is out of scope, read-only, no subagents. Ask for findings with file and line, severity, and evidence. Ask them to prove findings by running code where they can, and to list what they ruled out and what they didn't cover.
3. **Security review.** Brief the security reviewer to build an access matrix (actor by data path, with the expected status) and to look outside the obvious routes: exports, imports, admin paths, background jobs.
4. **Merge plan.** Check every finding against the code yourself. Mark each one confirmed, wrong or unproven. Write the plan into the repo's docs with taken, deferred (with a reason) and dropped items.
5. **Implementation.** Hand the plan to the implementer with the required checks. Read the whole returned diff before the cross-review and fix what you find.
6. **Cross-review.** Brief the cross-reviewer with what was taken, what was skipped and why, and the risks you expect. Ask it to test failure paths with the built code, not only the happy path.
7. **Fix and verify.** Fix what holds up. Run the full checks on a clean clone of the branch, in a sandbox when the host is loaded: lint, typecheck, every test suite, every supported database, and the production images built from a fresh clone, then started. A pass on a dead container is not a pass.
8. **Report.** Publish a Seol page with the tables below, then append one row per model to [references/evidence.md](references/evidence.md).

## Report tables

Every run uses the same tables so runs can be compared later.

- **Process:** step, model, effort, outcome. Include failed or skipped steps.
- **Findings side by side:** one row per issue, a column per reviewer (✓ reported, P proved), outcome (fixed, deferred, dropped).
- **Per reviewer:** findings, unique to that reviewer, proved, wrong, wall time, cost or usage if exposed.
- **What each model did well and badly.**
- **Checks run**, with where and the result.

## Pitfalls

- Green checks are not proof. Implementers have shipped regressions that passed every suite. The cross-review and the clean-clone checks exist to catch them.
- Severity labels drift. Re-rate each finding yourself before it shapes the plan.
- The lead grades models it also competes with. Keep the evidence (counts, proofs, outcomes) in the report so the verdicts can be checked.

## Stop conditions

- Commit locally only. Push, open a PR or merge only when the user asks for that stage.
- Stop and ask before anything touching production data, migrations on live databases or deploys.
