# Repo Maintainer Agent Loop

Use this reference when designing a recurring local coding-agent loop over a user's own repositories with GitHub issues/PRs and Codex/Claude/OpenCode worktrees.

## Core pattern

A good repo-maintainer loop behaves like a disciplined junior maintainer, not a noisy autopilot. It should:

1. Maintain a curated allowlist of real active projects.
2. Exclude external clones, templates, coursework, notes, inactive experiments, generated reports, and reference/upstream repos by default.
3. Run on a modest cadence, e.g. every 5 hours for low-volume solo development and subscription reset windows.
4. Separate read-only monitoring, review, issue discovery, implementation, and human-gated merge phases.
5. Never merge to protected branches such as `main` or `dev` without the user's explicit approval.

## Suggested phases

### 1. Read-only monitor

For each allowlisted repo:

- `git fetch --all --prune`
- capture branch, dirty state, ahead/behind, remotes
- list new commits, open PRs, and open issues via `gh`
- detect whether the repo has safe checks: test, lint, typecheck, build
- avoid edits in this phase

### 2. Review new changes

For new PRs or pushed branches:

- read the diff
- identify affected modules/components/APIs
- trace callers/callees one or two hops deeper
- inspect nearby tests, config, schemas, docs, and runtime paths
- run relevant focused checks where safe
- comment only when the finding is concrete and actionable

Avoid drive-by style nits unless they hide correctness, maintainability, security, or product problems.

### 3. Issue discovery

Open issues only when the agent can include:

- exact affected files
- reproduction, failing check, or clear reasoning path
- expected behaviour
- suspected cause or fix direction
- test/verification needed

Do not create vague issues like “improve architecture” or “clean up code”.

### 4. Implementation

For selected issues or requested features:

- create an isolated worktree outside the main checkout, e.g. `.worktrees/<repo>/<branch-slug>`
- create an `agent/...` branch such as `agent/fix-date-parsing` or `agent/feature-meet-dashboard`
- launch the coding agent scoped to that worktree
- run focused checks, then broader checks
- open a draft PR or append to the existing feature/fix branch, whichever is natural
- self-review the PR before handing it to the user

### 5. Human gate

Agents may usually automate:

- fetching metadata
- running checks
- creating local worktrees and branches
- opening issues when specific/reproducible
- opening draft PRs
- commenting on PRs with grounded findings
- pushing to agent-owned branches

Agents must require approval for:

- merging to `main`, `dev`, or release branches
- force-pushing user branches
- dependency upgrades with broad blast radius
- infra/deployment/security/auth changes
- closing issues as fixed without a merged PR
- comments on org/public repos the user does not fully control

## Allowlist/denylist discipline

Treat repo selection as part of the workflow, not an afterthought. For Semyon-style local repo scans, prefer actual maintained projects and explicitly exclude:

- external/not-owned repos
- CDC/hardware/event archives unless explicitly revived
- templates and UI report artifacts
- coursework/assignments except active product repos that happen to live under `university/`
- notes/Obsidian/file dumps
- upstream/reference clones nested inside real projects
- inactive experiments, CVs, and one-off prototypes

Keep ambiguous repos in a “maybe” bucket instead of feeding them to the agent loop.

## Quality bar

The loop is successful when it produces a small number of useful, evidence-backed issues/PRs. It is failing if it sprays low-value issues, generic review comments, or large unreviewed AI rewrites.