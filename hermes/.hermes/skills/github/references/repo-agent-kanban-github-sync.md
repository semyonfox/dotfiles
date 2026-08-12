# Repo-agent Kanban ↔ GitHub Sync Pattern

Use this when a recurring repo-agent sweep should publish useful repo-facing work while keeping private agent state durable.

## Roles

- Hermes Kanban: private control plane for agent state, blockers, retries, human gates, dirty local checkouts, and handoffs.
- GitHub Issues/PRs: repo-facing record for concrete bugs, feature requests, security findings, CI/test/docs gaps, and implemented changes.
- GitHub Projects v2: cross-repo public-ish queue/roadmap for issue and PR items, if auth scopes allow.

## Recommended flow

1. Scout repos and write the structured report.
2. Create/reuse Kanban cards with stable idempotency keys:
   - `repo-agent:pr:<repo>:<number>`
   - `repo-agent:blocker:<repo>:dirty-checkout`
   - `repo-agent:cleanup:<repo>:<artifact>`
   - `repo-agent:target:<repo>:<slug>`
3. For each concrete repo-visible finding, search existing open/recent issues before creating a new one.
4. If no equivalent exists, create a GitHub issue with labels such as `repo-agent`, `agent-generated`, `agent-candidate`, plus lane labels (`security`, `ci`, `tests`, `deadcode`, `performance`, `experimental-feature`).
5. Put the Kanban task id and source run id in the issue body. Comment the issue URL back onto the Kanban card.
6. If implementation happens, open a draft PR linking both the issue and Kanban task. Never auto-merge.
7. If Project v2 scopes exist, add created/reused issues and draft PRs to the `Agent Work` project and update status fields.
8. Digest the deltas: issues opened/closed, PRs opened/updated, project items added/skipped, Kanban cards created/reused, duplicate cleanup.

## Duplicate issue/card guard

Before `gh issue create`, search by title keywords and known source paths:

```bash
gh issue list -R OWNER/REPO --state all --search "repo-agent keyword path" --json number,title,state,url,labels
```

If a duplicate is found after creation, close the newer issue with a duplicate note and block/archive the duplicate Kanban card pointing to the canonical issue/card.

## Project scope check

`gh project` requires `project` / `read:project` scopes. If missing:

```bash
gh auth refresh -h github.com -s project -s read:project
```

Do not fail the entire sweep because Project sync is unavailable. Continue with issues/PRs/Kanban and leave a blocked Kanban card for the human.
