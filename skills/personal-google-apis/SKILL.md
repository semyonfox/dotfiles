---
name: personal-google-apis
description: "Use when generic setup map for Semyon's personal Google OAuth accounts and local helper tooling; load before task-specific Gmail, YouTube, or Google data skills when account/token context is needed."
version: 1.1.0
created_by: agent
related_skills:
  - personal-gmail
  - personal-youtube-analytics
  - personal-google-data

metadata:
  harness: [hermes]
---

# Personal Google APIs

Generic account/setup map for Semyon's personal Google OAuth integration. Use this when the task is about Google account plumbing, OAuth/token troubleshooting, account labels, API enablement, or deciding which narrower skill to load.

For task-specific work, prefer:

- `personal-gmail` — Gmail search/read/summarize/send/label workflows.
- `personal-youtube-analytics` — YouTube/FoxScope channel stats and analytics.
- `personal-google-data` — Calendar, Contacts/People API, and Drive metadata.

## Accounts and labels

Canonical token labels under `~/.hermes/google-personal/accounts/`:

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

There may also be an old typo-compatible label/symlink `foscopegaming`; prefer `foxscopegaming` in new work.

Inactive/stale Workspace context:

```text
semyon@oghmanotes.ie is inactive/stale for current personal Google work.
```

Only use GAM / old Workspace context if Semyon explicitly asks about OghmaNotes Workspace admin cleanup.

## Local paths

OAuth client and tokens:

```text
~/.hermes/google-personal/client_secret.json
~/.hermes/google-personal/accounts/personal/token.json
~/.hermes/google-personal/accounts/foxscopegaming/token.json
```

Dedicated Google API venv:

```text
~/.local/venvs/google-api
```

Helper scripts:

```bash
google-auth-account
gmail-whoami
yt-channel-stats
yt-analytics-last
```

Google Cloud CLI installed by apt:

```bash
gcloud   # /usr/bin/gcloud
gsutil   # /usr/bin/gsutil
bq       # /usr/bin/bq
```

GAM for old Workspace admin work:

```bash
gam      # /home/semyon/.local/bin/gam -> ~/bin/gam7/gam
```

## Security posture

- Never paste raw `token.json`, refresh tokens, client secrets, cookies, or browser profile data into chat.
- Default to read-only API calls unless Semyon explicitly asks to send, modify, delete, upload, or change settings.
- Always verify the account label before side effects.
- For emails, prefer metadata/snippets unless Semyon asks for body content.

## Current granted capability summary

Do not trust stale remembered scope summaries. Inspect the live token before claiming a capability:

```bash
python3 - <<'PY'
import json
from pathlib import Path
for p in sorted((Path.home()/'.hermes/google-personal/accounts').glob('*/token.json')):
    data = json.loads(p.read_text())
    print(p.parent.name)
    for scope in data.get('scopes', []):
        print(' ', scope)
PY
```

As of the Gmail draft-editing workflow in July 2026, `personal` was re-authorized for Gmail management scopes (`gmail.readonly`, `gmail.modify`, `gmail.send`, `gmail.labels`, `gmail.settings.basic`). Other accounts/scopes should still be verified live before use. Treat counts, channel stats, calendars, and granted scopes as stale until re-queried.

## Re-authorizing / scopes

List built-in scope presets:

```bash
google-auth-account --list-scopes
```

Authorize all built-in scopes:

```bash
google-auth-account personal --all-scopes --no-browser
google-auth-account foxscopegaming --all-scopes --no-browser
```

If using the PC browser for server OAuth, forward the callback port from the PC to the server first:

```bash
ssh -L 8765:localhost:8765 semyon@server
```

If port `8765` is busy:

```bash
google-auth-account foxscopegaming --all-scopes --port 8766 --no-browser
ssh -L 8766:localhost:8766 semyon@server
```

If Google grants fewer scopes than requested and a partial token is acceptable:

```bash
google-auth-account personal --all-scopes --allow-partial --no-browser
```

## Google Cloud project/API enablement

OAuth client project:

```text
golden-cove-493212-q2 / project number 522666167533
```

Important APIs:

- Gmail API
- YouTube Data API v3
- YouTube Analytics API
- YouTube Reporting API, optional
- Calendar API
- Google Tasks API
- People API
- Drive API

Useful links:

```text
https://console.cloud.google.com/apis/credentials?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/gmail.googleapis.com?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/youtube.googleapis.com?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/youtubeanalytics.googleapis.com?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/people.googleapis.com?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/calendar-json.googleapis.com?project=golden-cove-493212-q2
https://console.cloud.google.com/apis/library/drive.googleapis.com?project=golden-cove-493212-q2
```

If API calls return `accessNotConfigured`, enable the relevant API in this exact project and wait a few minutes.

## PC/Helium browser fallback

Semyon's PC is reachable as SSH alias `pc`; Helium is signed into his Google accounts.

Open a Google Console page on the PC:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1); hyprctl dispatch exec "helium-browser https://console.cloud.google.com/apis/credentials?project=golden-cove-493212-q2"'
```

Take a screenshot if needed:

```bash
ssh pc 'export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1 HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | head -1); grim /tmp/hermes-pc-screen.png'
scp pc:/tmp/hermes-pc-screen.png /tmp/hermes-pc-screen.png
```

Use browser control cautiously. Opening URLs and reading screenshots is fine; do not blindly click security/payment/account-deletion prompts.

## Troubleshooting

- `Missing token`: run `google-auth-account <label> --all-scopes --no-browser`.
- `Address already in use`: retry with `--port 8766` and forward that port if remote.
- `Scope has changed`: Google granted fewer scopes; verify OAuth consent/API setup or use `--allow-partial` if acceptable.
- `accessNotConfigured`: enable the relevant API in project `golden-cove-493212-q2`.
- `No YouTube channel found`: wrong account/token or account has no YouTube channel.
- `insufficientPermissions`: token lacks scope; re-authorize with `--all-scopes` or the needed preset.
