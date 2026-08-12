# Current deployment map

- Canonical task board: `personal-tasks`.
- Email-pipeline operations board: `email-triage`.
- Timer registry: `~/.hermes/state/personal-task-reminders.json`.
- Timer runner: `~/.hermes/scripts/personal_task_reminders.py`.
- Migration invariant: `camille-todo.md` is retired; a dated backup exists under `~/life-admin/archive/`.

## Verified cleanup pattern

When the user confirms a group of personal items is cleared:

1. Add a short confirmation comment to each still-open card.
2. Archive, rather than delete or reactivate/complete, the scheduled human-owned cards.
3. Run the reminder runner once to cancel links to the archived cards.
4. Confirm the intended remaining cards, no pending email batch, and an enabled successful email-triage run.
