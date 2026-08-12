# Recurring-agent Kanban pilot pattern

Use this when a recurring autonomous workflow already exists (usually cron + reports + Discord digest) and the user wants Kanban to become the durable workflow layer.

## When to use

- Cron output/history is hard to inspect or feels like “nothing is happening”.
- A workflow produces repeated human actions, blockers, draft PRs, incidents, or follow-ups.
- Multiple named profiles should own lanes over time.
- Work should survive restarts and be visible outside a single cron transcript.

## Conservative rollout

1. **Create a named board** for the workstream:
   ```bash
   hermes kanban boards create autonomous-workflows \
     --name 'Autonomous Workflows' \
     --description 'Durable board for recurring autonomous Hermes workflows'
   ```

2. **Seed a blocked parent tracking card**. Keep it blocked so the dispatcher does not accidentally start work while the pilot is being shaped.

3. **Seed child cards from latest durable state**, not from memory. For a repo-agent style workflow, read the latest report and create cards for:
   - open draft PRs awaiting review
   - dirty-checkout/user-work blockers
   - stale merged/closed agent artifacts eligible for cleanup
   - next high-value targets that are specific and deduped

4. **Use stable idempotency keys** so repeated cron runs update/comment instead of duplicating:
   - `repo-agent:pr:<repo>:<number>`
   - `repo-agent:blocker:<repo>:dirty-checkout`
   - `repo-agent:cleanup:<repo>:<artifact>`
   - `repo-agent:target:<repo>:<slug>`
   - `watchdog:incident:<type>`
   - `briefing:followup:<event-or-deadline-slug>`

5. **Keep human gates blocked** unless the user explicitly activates a card:
   - PR review/merge queues
   - dirty checkout preservation/discard decisions
   - watchdog/script modifications
   - external actions or deploys

6. **Wire the recurring job**:
   - Add `kanban` to the cron job's `enabled_toolsets`.
   - Update the prompt to create/update Kanban cards after writing its normal report.
   - Tell it to report Kanban deltas in the digest: cards created, cards updated/commented, cards completed/blocked.

7. **Comment on the parent card** with what was wired and what is intentionally blocked.

8. **Verify**:
   ```bash
   hermes kanban --board <slug> stats
   hermes kanban --board <slug> list
   hermes cron list
   ```
   During a setup-only pilot, expect `ready=0`, `running=0`, and all unsafe cards blocked.

## Good-fit workflows

### Repo-agent / autonomous code sweeps

Kanban should track durable action objects, not every scanned repo:
- one card per draft PR review
- one card per dirty-checkout/user-work blocker
- one card per cleanup candidate
- one card per safe next target

Cron remains the scheduler/scout; Kanban becomes the durable queue; GitHub remains external truth for PRs/issues/branches.

### System watchdogs

Keep watchdog scripts quiet when healthy. Create/update Kanban incident cards only for actionable recurring alerts such as disk pressure, NFS/media mount failures, gateway crash loops, stuck cron jobs, or repeated service failures.

### Briefings and event radars

Do not create cards for every news item. Create follow-up cards only for deadlines, registrations, applications, events, or opportunities that need a decision/action.

## Pitfalls

- Do not switch a whole board to ready just to “try it”; unblock one card and observe.
- Do not mirror cron output line-for-line into Kanban.
- Do not let Kanban workers merge PRs or mutate protected branches unless the user explicitly approves.
- Do not create dependency links merely for grouping; use a blocked parent card plus comments unless execution order truly matters.
