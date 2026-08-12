---
name: personal-google-data
description: "Use Semyon's Google Calendar, Contacts/People API, and Drive metadata access from personal OAuth tokens."
version: 1.0.0
created_by: agent
related_skills:
  - personal-google-apis

metadata:
  harness: [hermes]
---

# Personal Google Data

Use this when Semyon asks to inspect Google Calendar, **Google Tasks**, Contacts/People API data, or Google Drive metadata from his personal OAuth tokens.

Load `personal-google-apis` too only if OAuth setup/token/API enablement context is needed. For Gmail use `personal-gmail`; for YouTube use `personal-youtube-analytics`.

## Accounts

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

Old typo label `foscopegaming` may exist; prefer `foxscopegaming`.

## Safety posture

- This setup currently has read-only Calendar, Contacts, and Drive metadata scopes.
- Drive scope is metadata-only, not file-content access.
- Do not expose private contact details or calendar details unnecessarily; summarize minimally unless Semyon asks for specifics.
- Do not attempt destructive Drive/Calendar/Contacts changes unless Semyon explicitly authorizes and scopes are extended.

## Python boilerplate

Use the dedicated venv:

```bash
~/.local/venvs/google-api/bin/python script.py
```

```python
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

label = "personal"  # or "foxscopegaming"
token_path = Path.home() / ".hermes/google-personal/accounts" / label / "token.json"
scopes = [
    "https://www.googleapis.com/auth/calendar.readonly",
    "https://www.googleapis.com/auth/contacts.readonly",
    "https://www.googleapis.com/auth/drive.metadata.readonly",
]
creds = Credentials.from_authorized_user_file(str(token_path), scopes)
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    token_path.write_text(creds.to_json())
```

## Calendar

Build service:

```python
calendar = build("calendar", "v3", credentials=creds, cache_discovery=False)
```

List calendars:

```python
calendars = calendar.calendarList().list(maxResults=20).execute().get("items", [])
```

List upcoming events:

```python
from datetime import datetime, timezone, timedelta
now = datetime.now(timezone.utc).isoformat()
end = (datetime.now(timezone.utc) + timedelta(days=14)).isoformat()
events = calendar.events().list(
    calendarId="primary",
    timeMin=now,
    timeMax=end,
    singleEvents=True,
    orderBy="startTime",
    maxResults=20,
).execute().get("items", [])
```

Initially observed calendars on `personal` included:

```text
Holidays in Ireland
Family
Tuam Swimming
semyon.fox@gmail.com
SEMYON FOX Calendar (Canvas)
```

Treat this as stale; re-query live before reporting.

## Google Tasks

Google Tasks is read-only in this workflow. Semyon’s current preference is to mirror open tasks into canonical `personal-tasks` cards while preserving each Google Task list and parent/subtask links; never edit, complete, or delete Google Tasks.

The token needs `https://www.googleapis.com/auth/tasks.readonly`; re-authorize with `google-auth-account personal --all-scopes --no-browser` if absent.

```python
tasks = build("tasks", "v1", credentials=creds, cache_discovery=False)
tasklists = tasks.tasklists().list(maxResults=100).execute().get("items", [])
for tasklist in tasklists:
    items = tasks.tasks().list(
        tasklist=tasklist["id"], showCompleted=False, showHidden=False, maxResults=100,
    ).execute().get("items", [])
```

For monitoring, Google Tasks is synced every six hours; report only incomplete/due-soon tasks and dedupe by Google Task ID. Semyon’s current preference is to import open Google Tasks into the canonical `personal-tasks` board, using `google-task:<id>` idempotency keys and the non-dispatchable `semyon-human` lane; do not edit Google Tasks.

## Contacts / People API

Build service:

```python
people = build("people", "v1", credentials=creds, cache_discovery=False)
```

List contacts:

```python
connections = people.people().connections().list(
    resourceName="people/me",
    pageSize=20,
    personFields="names,emailAddresses,phoneNumbers,organizations",
).execute().get("connections", [])
```

Minimize exposure: return names/counts or targeted matches; do not dump entire address books.

## Drive metadata

Build service:

```python
drive = build("drive", "v3", credentials=creds, cache_discovery=False)
```

List recent files/folders metadata:

```python
files = drive.files().list(
    pageSize=20,
    fields="files(id,name,mimeType,modifiedTime,owners/emailAddress,webViewLink)",
    orderBy="modifiedTime desc",
).execute().get("files", [])
```

Search by name or mime type:

```python
files = drive.files().list(
    q="name contains 'invoice' and trashed=false",
    pageSize=20,
    fields="files(id,name,mimeType,modifiedTime,webViewLink)",
).execute().get("files", [])
```

Remember: with `drive.metadata.readonly`, you can list names/metadata/links but cannot download file contents.

## Common task patterns

### Calendar briefing

1. Query primary calendar and any named calendars Semyon mentions.
2. Use the requested time window.
3. Summarize date/time/title/location; avoid dumping attendee details unless useful.

### Calendar reminders

Use `~/.hermes/scripts/google_calendar_reminders.py` with the `Google Calendar reminders` 15-minute script-only cron. It is read-only and sends one reminder at 09:00 Dublin time the day before each event plus another two hours before timed events. Calendar events stay events; do not create personal-task cards unless Semyon explicitly turns an event into an action.

### Find a contact

1. Search People API by name/email if possible.
2. Return likely matches with minimal details.
3. Ask before using contact details externally.

### Find Drive item metadata

1. Search metadata by name/time/type.
2. Return file name, modified time, mime type, and webViewLink if useful.
3. If Semyon needs file contents, explain current scope is metadata-only and re-auth would need Drive readonly/content scope.

## Troubleshooting

- `Missing token`: load `personal-google-apis` and re-authorize.
- `insufficientPermissions`: token lacks the needed readonly scope; re-authorize with all scopes.
- `accessNotConfigured`: Calendar/People/Drive API disabled in Google Cloud project; load `personal-google-apis` for exact links.
- Empty contacts/calendar: may genuinely be empty for that account; verify the account label with userinfo/Gmail if needed.
