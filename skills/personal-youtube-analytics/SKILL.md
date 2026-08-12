---
name: personal-youtube-analytics
description: "Fetch Semyon's personal/FoxScope YouTube channel stats and analytics using local OAuth tokens and YouTube APIs."
version: 1.0.0
created_by: agent
related_skills:
  - personal-google-apis

metadata:
  harness: [hermes]
---

# Personal YouTube Analytics

Use this when Semyon asks for YouTube channel stats, FoxScope performance, video/channel analytics, watch time, subscriber changes, or YouTube API troubleshooting.

Load `personal-google-apis` too only if you need OAuth setup, API enablement links, token paths, or PC/Helium browser fallback. For ordinary YouTube stats/analytics, this skill should be enough.

## Accounts and channels

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

Known channels:

```text
personal / Semyon Fox: UCGcXTMIJQfWz07Azq_gFC5w
foxscopegaming / FoxScope: UCNEDUQI4vrEfS5ZvNwc2idw
```

Old typo label `foscopegaming` may exist; prefer `foxscopegaming`.

## Safety posture

- Reading channel stats/analytics is fine when requested.
- Uploading videos, changing metadata, deleting comments/videos, or channel management needs explicit instruction.
- Treat counts as live data: re-query before reporting.

## Quick commands

Channel stats:

```bash
yt-channel-stats personal
yt-channel-stats foxscopegaming
```

Daily analytics rows:

```bash
yt-analytics-last foxscopegaming UCNEDUQI4vrEfS5ZvNwc2idw --days 28
yt-analytics-last personal UCGcXTMIJQfWz07Azq_gFC5w --days 28
```

## Python pattern

Use the dedicated venv:

```bash
~/.local/venvs/google-api/bin/python script.py
```

Boilerplate:

```python
from pathlib import Path
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.discovery import build

SCOPES = [
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/yt-analytics.readonly",
    "https://www.googleapis.com/auth/yt-analytics-monetary.readonly",
]
label = "foxscopegaming"
token_path = Path.home() / ".hermes/google-personal/accounts" / label / "token.json"
creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)
if creds.expired and creds.refresh_token:
    creds.refresh(Request())
    token_path.write_text(creds.to_json())

youtube = build("youtube", "v3", credentials=creds, cache_discovery=False)
analytics = build("youtubeAnalytics", "v2", credentials=creds, cache_discovery=False)
```

## Channel stats

```python
resp = youtube.channels().list(
    part="snippet,statistics,contentDetails",
    mine=True,
).execute()
```

Report useful fields:

```text
channel title
channel ID
viewCount
subscriberCount
videoCount
uploads playlist ID
```

## Analytics query pattern

Daily trend:

```python
resp = analytics.reports().query(
    ids="channel==UCNEDUQI4vrEfS5ZvNwc2idw",
    startDate="YYYY-MM-DD",
    endDate="YYYY-MM-DD",
    metrics="views,estimatedMinutesWatched,averageViewDuration,subscribersGained,subscribersLost",
    dimensions="day",
    sort="day",
).execute()
```

Useful metric sets:

```text
views,estimatedMinutesWatched,averageViewDuration
subscribersGained,subscribersLost
likes,dislikes,comments,shares
estimatedRevenue,estimatedAdRevenue,grossRevenue   # may require monetary scope and monetized channel access
```

Useful dimensions:

```text
day
video
country
province
subscribedStatus
trafficSourceType
insightTrafficSourceType
playlist
```

Not every dimension/metric combination is valid. If Google rejects a query, simplify to `day` + core metrics, then add dimensions gradually.

### FoxScope API limitation observed July 2026

For FoxScope, channel-level aggregate and `day` reports work, including `averageViewPercentage`, `engagedViews`, `subscribedStatus`, and device dimensions. The current API rejected `dimensions="video"` historical reports and rejected `trafficSourceType`, `newViewers`, `returningViewers`, and `uniqueViewers` identifiers. Do not invent per-video historic trends or returning-viewer figures from channel-level data. Export current public per-video totals through the Data API and direct the creator to Studio for video-level retention curves, `Viewed vs swiped away`, feed impressions, traffic sources, and returning viewers.

## Common task patterns

### FoxScope quick health report

1. Run `yt-channel-stats foxscopegaming`.
2. Run `yt-analytics-last foxscopegaming UCNEDUQI4vrEfS5ZvNwc2idw --days 28`.
3. Summarize trend: total views, rough daily average, best/worst day, subscriber net change, notable dips/spikes.

### Compare personal vs FoxScope

1. Run channel stats for both labels.
2. Use analytics only where meaningful; personal channel currently has no/low activity.
3. Keep recommendations practical: upload cadence, titles/thumbnails/topics only if data supports it.

### Video-level analytics

1. List recent uploads from the uploads playlist.
2. Query analytics with `dimensions="video"` and relevant metrics.
3. Join video IDs to titles from YouTube Data API.

### Dormant-channel revival and footage archives

When Semyon asks whether to resurrect FoxScope or turn old recordings into content, collect 28/90/365-day aggregate and video-level evidence, establish the real dormant period, then inspect the footage archive read-only. Distinguish a functioning channel from a viable archive, select the first experiment from topics still receiving views, and design around low editing throughput rather than raw-footage volume.

Use `references/dormant-channel-revival.md` for the bounded Shorts experiment, reusable editing workflow, OBS replay-buffer intake, success criteria, and safe handling of likely MKV/MP4 remux pairs.

## Troubleshooting

- `Missing token`: load `personal-google-apis` and run `google-auth-account <label> --all-scopes --no-browser`.
- `accessNotConfigured`: YouTube Data/Analytics API disabled or not propagated in project `golden-cove-493212-q2`; load `personal-google-apis` for links.
- `No YouTube channel found`: wrong Google account/token or account has no channel.
- `insufficientPermissions`: re-authorize with all scopes or YouTube scopes.
- `forbidden` on monetary metrics: channel may not have monetization/revenue access, or token lacks `yt-analytics-monetary.readonly`.
