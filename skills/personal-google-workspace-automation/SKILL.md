---
name: personal-google-workspace-automation
description: "Use when safely operate Semyon's Gmail, Google Tasks, and Google Calendar as one personal intake, task, and reminder system."

metadata:
  harness: [hermes]
---

# Personal Google Workspace automation

Use for cross-service work involving Semyon's Gmail, Google Tasks, Google Calendar, task mirroring, reminders, OAuth scopes, or the boundary between them.

## Canonical model

- **Gmail** is incoming communication and evidence. The incremental collector uses per-account Gmail History API checkpoints; it scans all changes since the acknowledged checkpoint, not a fixed newest-N sample.
- **Google Tasks** is a read-only source at the Google API boundary and is mirrored into the canonical `personal-tasks` Kanban board when Semyon has enabled that integration.
- **`personal-tasks`** is the canonical task state. Personal cards use the `semyon-human` lane and `scheduled` state so they never enter autonomous agent dispatch.
- **Calendar** is an event/reminder source. Do not create a task merely because an event exists; only make one if Semyon explicitly turns the event into an action.
- **Email Triage** is an operational board only, not a second todo list.

## Shared OAuth token: preserve grants on refresh

The personal token is shared across Google APIs. Never load it with a narrow single-service scope and then overwrite the token using `creds.to_json()` after refresh: that can erase the other stored grants.

Use the token's stored scope list and preserve it when persisting a refresh:

```python
import json
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request

path = Path.home() / ".hermes/google-personal/accounts/personal/token.json"
raw = json.loads(path.read_text())
granted_scopes = raw.get("scopes") or ["https://www.googleapis.com/auth/calendar.readonly"]
creds = Credentials.from_authorized_user_info(raw, granted_scopes)
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    refreshed = json.loads(creds.to_json())
    refreshed["scopes"] = granted_scopes
    path.write_text(json.dumps(refreshed))
```

If scopes are absent, re-authorize once with:

```bash
google-auth-account personal --all-scopes --no-browser
```

Verify the needed scopes and a real API call before claiming access.

## Google Tasks mirror

1. List every task list and every open task using pagination. Keep Google API access read-only.
2. Create or reuse each task card with `google-task:<google-task-id>` idempotency key.
3. Preserve the original structure rather than flattening it:
   - create one non-actionable structure card per list with `google-tasklist:<list-id>`;
   - link root tasks to their list card;
   - link subtasks to their Google parent task card.
4. Use `--assignee semyon-human --initial-status blocked`, then immediately schedule the card. This prevents autonomous dispatch.
5. On later syncs, create new cards idempotently and update/link their hierarchy. Never edit, complete, or delete the Google Tasks source.

## Cadence

Use cadence based on urgency, not one universal poll interval:

| Flow | Cadence | Reason |
|---|---:|---|
| Gmail incremental triage | 2 hours | Exhaustive checkpointed intake; agent classifies only meaningful actions. |
| Google Tasks mirror | 6 hours | Slow-moving source; idempotency makes repetition safe. |
| Calendar reminder check | 15 minutes, silent unless due | Supports approximately timed day-before and two-hour alerts. |
| Explicit task timers | 15 minutes, silent unless due | Timers are linked to open canonical cards. |

A six-hour Calendar sweep cannot reliably deliver a two-hour reminder. Keep exact-time reminder flows quiet and more frequent; slow sources can be coarser.

## Calendar reminders

- Read calendars/events only; exclude holiday-calendar noise from appointment reminders.
- Deduplicate reminder delivery by calendar/event/recurrence instance and trigger type.
- Default event reminders: 09:00 Europe/Dublin the day before, plus two hours before a timed event.
- Do not emit all-clear messages.
- Keep event state in a separate reminder-state file, never as duplicate todo cards.

## Verification

Before reporting success:

1. Confirm OAuth scope presence and execute a read-only API list call.
2. Verify Kanban import counts and that every Google Task card has its intended parent/list link.
3. Verify all imported personal cards are scheduled and assigned `semyon-human`.
4. Run the watcher twice; the second run must create no duplicate cards and produce no alert without a real change.
5. Check cron schedules and delivery targets; call out any failed/stale channel target rather than hiding it.
