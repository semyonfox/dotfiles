# Kanban ↔ GitHub bridge for recurring repo-agent workflows

Use this when a recurring autonomous repo workflow should have both private agent state and repo-visible GitHub state.

## Division of responsibility

- **Hermes Kanban** is the private/internal control plane: assignee profile, blocked/ready/running state, dirty-checkout decisions, handoffs, retries, human gates, and recovery context.
- **GitHub Issues/PRs/Projects** are the repo/product-facing truth: bugs, feature requests, CI/test work, draft PRs, review discussion, project status, and merge history.

Do not replace one with the other. Kanban routes and remembers agent work; GitHub records evidence-backed repo work.

## Recommended flow

1. Cron/scout scans managed repos and updates Kanban cards with stable idempotency keys.
2. If a finding is concrete and repo-visible, open or update a GitHub issue in the affected repo.
3. Link the GitHub issue back to the Kanban card and comment the issue URL on the card.
4. Implementation happens on an `agent/*` branch in an isolated worktree.
5. Open a draft PR linked to both the GitHub issue and Kanban card.
6. Add issues/PRs to a GitHub Project such as `Agent Work` when project auth scope is available.
7. Keep merge/close decisions human-gated unless the user explicitly approves.

## What becomes GitHub-visible

Create GitHub issues for:

- reproducible bugs
- failing checks/builds/CI
- security/privacy/auth/data-safety findings with evidence
- missing tests around fragile code
- scoped feature requests or experimental features
- performance issues with evidence
- docs gaps that matter
- dead-code cleanup worth tracking

Keep Kanban-only:

- dirty local checkout state
- agent retry/failure noise
- vague architecture ideas
- private/local workflow decisions
- untracked personal files or generated/cache/LFS housekeeping unless it affects repo health
- “human needs to decide what to do with local files” blockers

## Idempotency key patterns

Use stable keys so repeated cron runs update/comment instead of duplicating cards:

- `repo-agent:pr:<repo>:<number>`
- `repo-agent:blocker:<repo>:dirty-checkout`
- `repo-agent:cleanup:<repo>:<artifact>`
- `repo-agent:target:<repo>:<slug>`

## GitHub labels

Provision these on managed repos and use consistently:

- `repo-agent`
- `agent-candidate`
- `agent-generated`
- `agent-needs-human`
- `agent-blocked`
- `agent-fix-ready`
- `experimental-feature`
- lane labels such as `deadcode`, `ci`, `tests`, `security`, `performance`

## Issue/PR body footer

GitHub issue footer:

```md
---
Repo-agent:
- Kanban: t_xxxxxxxx
- Source run: repo-agent-YYYYMMDD...
- Lane: bugfix | tests | ci | security | docs | deadcode | experimental-feature
- Confidence: low | medium | high
```

Draft PR footer:

```md
---
Repo-agent validation:
- Kanban: t_xxxxxxxx
- Issue: #123
- Lane: tests
- Base branch: dev
- Checks: npm test, npm run lint
- Opus verdict: PASS_OPEN_PR
- Status: awaiting maintainer review/merge
```

## GitHub Projects setup

The GitHub CLI needs project scopes before Projects v2 commands work:

```bash
gh auth refresh -h github.com -s project -s read:project
```

Recommended project: `Agent Work` under the repo owner/user. Suggested fields:

- `Status`: Needs triage, Ready, In progress, In review, Blocked, Done, Cancelled
- `Repo`
- `Lane`
- `Risk`
- `Agent status`
- `Kanban task`

Status mapping:

- new issue → Needs triage / Ready
- implementation task → In progress
- draft PR → In review
- human-gated or Kanban blocked → Blocked
- merged/resolved → Done
- closed unmerged → Cancelled

## Pitfalls

- Do not create a GitHub issue for every Kanban blocker; local workflow blockers usually belong only in Kanban.
- Do not dump every news/briefing item into Kanban or GitHub. Only actionable follow-ups become cards.
- Do not treat GitHub Projects auth failure as a repo-agent failure. Continue with issues/PRs/Kanban and leave a Kanban setup blocker for project scope.
- Do not auto-merge PRs from Kanban or GitHub Project status. Human approval remains the gate.
