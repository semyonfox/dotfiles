# Script-backed watch windows for Hermes cron

This reference captures a reusable pattern from a Canvas results polling job.

## Problem

A no-agent Hermes cron job pointed directly at a JavaScript module:

```text
script: canvas_results_watch.mjs
no_agent: true
```

The job failed because the cron runner executed the `.mjs` file as Python despite its Node shebang:

```text
File "/home/semyon/.hermes/scripts/canvas_results_watch.mjs", line 2
    import fs from 'node:fs';
              ^^^^
SyntaxError: invalid syntax
```

## Fix

Create a shell wrapper and update cron to run the wrapper:

```bash
#!/usr/bin/env bash
set -euo pipefail
exec /home/semyon/.local/bin/node /home/semyon/.hermes/scripts/canvas_results_watch.mjs
```

Then verify both layers:

```bash
bash -n /home/semyon/.hermes/scripts/canvas_results_watch.sh
node --check /home/semyon/.hermes/scripts/canvas_results_watch.mjs
bash /home/semyon/.hermes/scripts/canvas_results_watch.sh
```

The no-change case should exit `0` with empty stdout so no-agent delivery stays silent.

## High-frequency event window

When the user wants many scans around a likely event time but not permanent hammering:

1. Set the cron schedule to `every 1m`.
2. Put the real polling window in the wrapper.
3. Exit `0` silently before the window.
4. After the window, pause the cron job and exit silently.
5. If the underlying script detects the target condition, print exactly one alert and pause the job.

Example wrapper gate:

```bash
hour=$(TZ=Europe/Dublin date +%H)
minute=$(TZ=Europe/Dublin date +%M)
now=$((10#$hour * 60 + 10#$minute))
start=$((11 * 60 + 40))
end=$((12 * 60 + 10))

if (( now < start )); then
  exit 0
fi

if (( now > end )); then
  "$HERMES" cron pause "$JOB_ID" >/dev/null 2>&1 || true
  exit 0
fi

CANVAS_RESULTS_CRON_JOB_ID="$JOB_ID" exec "$NODE" "$SCRIPT"
```

Example JS self-pause after printing the alert:

```js
console.log(message);
try {
  execFileSync('/home/semyon/.local/bin/hermes', ['cron', 'pause', cronJobId], { stdio: 'ignore' });
} catch {}
```

## Notes

- Use absolute paths in cron wrappers; cron/gateway environments often do not have the same PATH as an interactive shell.
- `cronjob(action='run')` can mark the job to run on the next scheduler tick; it is not a substitute for manually executing the script when validating runtime behavior.
- Keep the alert print before the pause attempt.
- For `no_agent=true`, empty stdout means no delivery; this is the desired no-change path.
