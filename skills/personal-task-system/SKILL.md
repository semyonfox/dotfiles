---
name: personal-task-system
description: "Use when maintain Semyon's canonical Personal Tasks Kanban board and task-linked reminders. Use whenever an email creates a commitment or Semyon asks to track, remind, defer, or complete personal work."

metadata:
  harness: [hermes]
---

# Personal task system

## Boundaries

- **Gmail/email triage** owns incoming mail and thread context. Email is not itself a task.
- **`personal-tasks` Kanban** owns all durable commitments, from either email or direct chat requests.
- **`~/.hermes/state/personal-task-reminders.json`** owns timer state only. Every reminder references exactly one `personal-tasks` task ID.
- **`email-triage` Kanban** is only for collector/auth/history/recovery health. Never add ordinary personal work there.
- Never recreate or use `/home/semyon/life-admin/camille-todo.md`; it was retired with a dated backup under `~/life-admin/archive/`.

## Create or update a task

1. Decide whether there is a real action, decision, deadline, reply, appointment, or intentional follow-up. Do not make cards for newsletters, receipts, routine notifications, or purely informational mail.
2. For an email-derived task, use a stable idempotency key `email:<account>:<thread-id>`. For a direct request use `manual:<short-slug>`.
3. Create a concise card on the canonical board:

   ```bash
   hermes kanban --board personal-tasks create "<action title>" \
     --body $'Source: <email triage | direct request>.\nDue: <exact date or no deadline stated>.\nNext action: <one concrete action>.' \
     --priority <1-4> --idempotency-key '<key>' --created-by Camille \
     --assignee semyon-human --initial-status blocked
   ```

4. Immediately park the returned ID in `scheduled`. This is intentional: Hermes Kanban is also an agent-work dispatcher, so `todo`/`blocked` can auto-promote to `ready`. Personal cards are human-owned and must not be dispatched:

   ```bash
   hermes kanban --board personal-tasks schedule <task-id> \
     'Human-owned personal task; surfaced by Camille briefing/reminders, never auto-dispatched.'
   ```

5. For a later email on the same commitment, reuse the idempotency key and append a factual comment; do not duplicate the task. Complete only when evidence clearly proves it is resolved.

## Add a reminder

Only add a timer for an explicit deadline, explicitly requested reminder, or deliberate review/follow-up. Do not invent timing. Use ISO-8601 with timezone and a stable reminder ID:

```bash
python3 ~/.hermes/the local supporting file \
  --id '<task-key>-YYYY-MM-DD' --task-id <task-id> \
  --at 'YYYY-MM-DDTHH:MM:SS+01:00' --message '<short reminder>'
```

The every-15-minute `Personal task reminders` cron sends only due reminders whose linked cards are still open; it retires reminders for done/archived cards. The morning briefing reads `personal-tasks`, not Gmail or Markdown.

## Completion and retirement

- Personal cards are deliberately `scheduled` so the agent dispatcher cannot claim them. Hermes cannot directly `complete` that state without first reactivating it, which risks dispatch. When Semyon says a scheduled personal task is done, append a concise confirmation comment and **archive** it instead; this preserves the audit trail and suppresses linked future reminders safely.
- Do not delete cards. Archive only user-confirmed completions, duplicates, cancelled commitments, and clearly obsolete historical work.
- An archived task automatically suppresses its linked future reminders.
