---
name: personal-operations
description: "Use when operate Semyon's personal email intake, canonical task board, reminders, and daily briefing without duplicate lists or accidental agent dispatch."

metadata:
  harness: [hermes]
---

# Personal operations workflow

## Ownership boundary

Keep three distinct systems:

1. **Email triage** owns Gmail ingestion, thread context, and classification. Email is evidence, not automatically a task.
2. **Personal Tasks Kanban** owns durable human commitments from email or direct requests. It is the only active task source of truth.
3. **Reminder registry** owns timing only. Every timer references a task card; it never becomes a second task database.

Do not maintain a parallel Markdown todo. Preserve old lists only as dated archives.

## Intake decisions

For every incoming email, choose exactly one outcome:

- Ignore: receipt, newsletter, routine notification, resolved thread, code, marketing.
- Notify once: time-sensitive information that needs awareness but no follow-up.
- Create/update task: concrete action, reply, decision, deadline, appointment, or deliberate follow-up.
- Resolve an existing task: only with clear evidence.

Email-derived tasks must carry a stable source/idempotency key and concise source, due, and next-action context. Later mail updates that same task instead of duplicating it.

## Hermes Kanban safety

Hermes Kanban is also an agent-work dispatcher. Personal cards must never be left in a state that can silently route them to an autonomous worker. In this deployment, create a task with a stable key and then immediately park it in `scheduled` as a human-owned card. Use the daily briefing and reminder runner to surface it.

For a user-confirmed cleared item, add a concise audit comment and archive the card. Do not reactivate it just to mark it complete: reactivation can create an accidental dispatch window.

## Reminders and briefings

- Add timers only for explicit deadlines, requested nudges, or deliberate follow-up dates. Never invent dates.
- The reminder runner must check that the linked card is still open; retire/cancel its timer if the card is archived or done.
- After bulk archival, run the reminder reconciler once so cancelled timers do not wait for the next scheduled tick.
- The morning briefing reads the task board only: overdue, upcoming, practical next actions, and real waiting decisions.
- The email watcher reads Gmail only and hands off durable outcomes to tasks.

## Resume verification

When resuming the email pipeline after cleanup, verify:

1. only intended task cards remain open;
2. the reminder registry has no live timer for archived cards;
3. the email collector has no pending unacknowledged batch;
4. the scheduled email job is enabled and has completed a successful run.
