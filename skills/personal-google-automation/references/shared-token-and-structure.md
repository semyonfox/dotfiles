# Shared token and source-structure rules

## Scope-refresh failure mode

The same personal OAuth token serves Gmail, Google Tasks and Calendar. A helper that loads the token with only one requested scope and persists `creds.to_json()` after refresh can replace the token's stored scope list with that narrow scope. The next API needing another scope then fails with `403 insufficient authentication scopes`.

**Fix:** load using the token's existing `scopes` array and explicitly preserve that array when persisting refreshed credentials. If scopes were already narrowed, use a full reauthorization (`google-auth-account personal --all-scopes --no-browser`) before enabling monitors.

## Google Tasks import contract

- Import all pages of lists and open tasks.
- Mirror task lists as stable parent cards (`google-tasklist:<list-id>`).
- Mirror each task with `google-task:<task-id>`.
- Preserve Google `parent` links as Kanban parent links; root tasks link to their task-list card.
- Preserve list ID/name, parent ID, task ID, due, notes and updated timestamp in cards or sync state.
- Use a human-only non-dispatchable lane; schedule cards immediately.
- Test idempotency by rerunning an unchanged import and confirming card count does not rise.

## Calendar reminders

Calendar remains read-only. A notification watcher should key reminders by calendar ID, event ID, occurrence start and lead time, use `singleEvents=True`, and suppress notifications when an event is cancelled or changed. Default delivery is day-before at 09:00 Europe/Dublin plus two hours before timed events.
