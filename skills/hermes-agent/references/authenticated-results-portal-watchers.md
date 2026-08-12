# Authenticated results portal watchers

Session-derived pattern for official exam/results portals where the user supplies a browser `curl` capture containing cookies and form credentials.

## When to use

Use under the `hermes-cron-operations` umbrella when a user wants a short-lived high-frequency watcher for an authenticated web portal and the source of truth is a classic HTML form page rather than an API.

## Safe handling of captures

1. Treat pasted cookies/passwords as live credentials.
2. Move the capture immediately into a protected file such as:
   ```bash
   mkdir -p ~/.hermes/secrets
   cp <capture> ~/.hermes/secrets/results-portal-curl.sh
   chmod 600 ~/.hermes/secrets/results-portal-curl.sh
   ```
3. Remove loose local cache copies if feasible.
4. In user-facing replies, mention only the protected path and the watcher behavior. Do not repeat cookies, IDs, passwords, or request bodies.
5. Recommend rotating the password/session after the watch if the credential was pasted through a messaging platform.

## Request flow

Some legacy result pages expire on refresh or direct replay. If direct `curl` to the result endpoint says “Page Expired”, reproduce the browser flow:

1. Parse from the saved curl capture:
   - result URL
   - cookie header
   - POST body
   - user-agent
   - referer/form URL
2. Create a single HTTP session/cookie jar.
3. Seed it with the captured cookies.
4. `GET` the referer/form URL first to establish a fresh ASP/session state.
5. `POST` the captured form body to the result URL in the same session.
6. Save the latest HTML under a non-secret diagnostics directory if useful, but do not save credential headers there.

Python sketch:

```python
import re, requests
from pathlib import Path

capture = Path('/home/semyon/.hermes/secrets/results-portal-curl.sh').read_text()
url = re.search(r"curl '([^']+)'", capture).group(1)
cookie = re.search(r"\s-b '([^']+)'", capture).group(1)
data = re.search(r"--data-raw '([^']+)'", capture).group(1)
ua = re.search(r"-H 'User-Agent: ([^']+)'", capture).group(1)
referer = re.search(r"-H 'Referer: ([^']+)'", capture).group(1)

s = requests.Session()
for part in cookie.split('; '):
    if '=' in part:
        k, v = part.split('=', 1)
        s.cookies.set(k, v, domain='example.edu', path='/')
headers = {'User-Agent': ua, 'Accept': 'text/html,*/*', 'Accept-Language': 'en-GB,en;q=0.9'}
s.get(referer, headers=headers, timeout=30).raise_for_status()
r = s.post(url, headers={**headers, 'Referer': referer, 'Content-Type': 'application/x-www-form-urlencoded'}, data=data, timeout=30)
r.raise_for_status()
```

Adjust the cookie domain to the actual portal host.

## Change detection

- Extract visible text from HTML and collapse whitespace.
- Normalize away per-request noise before hashing/comparing:
  - generated timestamps
  - page render time
  - volatile session chrome
- Track state in `~/.hermes/state/<watch-name>.json`:
  - last normalized digest
  - last `not_ready` boolean
  - one-shot flags for reported auth/expired errors
- Alert when:
  - the page no longer contains “not yet available” / “will be available”, or
  - the normalized digest changes and the page is no longer in the not-ready state.
- Stay silent for normal no-change polls.
- Print the alert before attempting to pause the cron job.

## Failure handling

- “Page expired”: report once, then keep trying if the watcher is using the GET-then-POST flow; persistent failures may mean fresh cookies are needed.
- Login/access page: report once that fresh login cookies may be needed.
- Network or parse errors: report only when the error string changes; minute-by-minute failure spam is worse than silence.

## Cron behavior

Use a no-agent script-backed cron job:

- `schedule='every 1m'` for the short release window.
- `no_agent=true` so stdout is delivered verbatim and empty stdout is silent.
- Pause the job automatically once results appear.
- Optionally include a time gate or expiry wrapper if polling should stop after a window even without results.
