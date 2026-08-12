---
name: personal-google-automation
description: "Use when safely operate and monitor Semyon's personal Google Tasks and Google Calendar through local OAuth helpers, preserving source structure and avoiding duplicate reminders."

metadata:
  harness: [hermes]
---

# Personal Google automation

Use this for recurring monitoring, import/reconciliation, reminders, or token troubleshooting involving Semyon's Google Tasks and Calendar. Load the narrower personal Google data/API skills too for account labels and API setup.

## Ownership boundaries

- Google Tasks owns its task lists, parent/subtask hierarchy, completion state, and task edits.
- Google Calendar owns events, recurrences, RSVP details, and event edits.
- Hermes `personal-tasks` may mirror Google Tasks only when Semyon asks to import/sync them; it is not a licence to edit Google Tasks.
- Calendar events are not automatically personal tasks. Use an event-reminder watcher unless Semyon specifically asks to create a task from an event.

## Google Tasks mirroring

1. Fetch all task lists and every open task, paging list and task results. Retain Google task ID, list ID/name, parent ID, position, title, notes, due date, and updated timestamp.
2. Use idempotency keys:
   - list card: `google-tasklist:<list-id>`
   - task card: `google-task:<task-id>`
3. **Preserve source structure.** Create a parent card for each Google Task list. Link root tasks beneath that list card; link subtasks beneath their Google parent task card. Keep list and parent identifiers in the card body/metadata.
4. Use a non-dispatchable human lane and park mirror cards as scheduled so the Kanban worker dispatcher never takes personal tasks autonomously.
5. On later scans, create only unknown IDs. Add a factual comment for title/due/notes/parent changes. Do not flatten lists into one backlog or create duplicates.
6. Do not infer that a missing open task was completed without a full reconciliation strategy; report/remind first unless Semyon has explicitly chosen completion mirroring.

## Calendar reminders

1. Query all relevant calendars using `singleEvents=True` so recurring occurrences receive their own occurrence start.
2. Deduplicate reminder state by `calendar-id:event-id:occurrence-start:lead-time`.
3. Default reminder policy when Semyon says to keep an eye on events:
   - day before at 09:00 Europe/Dublin;
   - two hours before timed events;
   - for all-day events, use only the day-before reminder unless asked otherwise.
4. Re-fetch events each pass. Event edits/cancellations must update/suppress previously scheduled notifications.
5. Deliver only imminent/new/changed events; do not repeatedly dump the whole calendar or attendee details.

## Shared OAuth-token safety

All personal Google APIs use the same account `token.json`. Never narrow the stored scopes accidentally:

```python
stored = json.loads(token_path.read_text())
granted_scopes = stored.get("scopes") or requested_scopes
creds = Credentials.from_authorized_user_info(stored, granted_scopes)
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    refreshed = json.loads(creds.to_json())
    refreshed["scopes"] = granted_scopes
    token_path.write_text(json.dumps(refreshed))
```

Loading a shared token with one narrow scope and then writing `creds.to_json()` after refresh can overwrite the token's full scope list. If that has occurred, re-authorize all required scopes with:

```bash
google-auth-account personal --all-scopes --no-browser
```

## Verification

- Confirm the token includes `tasks.readonly` before calling Google Tasks and `calendar.readonly` before Calendar.
- Confirm the relevant API can list task lists/calendars before creating a monitor.
- Test the watcher twice: first pass establishes/imports the baseline; second unchanged pass must produce no duplicate cards or notifications.
- Keep token files mode `0600`, state files mode `0600`, and never expose their contents.

See `references/shared-token-and-structure.md` for the concrete scope-refresh and hierarchy rules discovered in practice.
