# R2D2 script-only watchdogs: bash, NFS timeouts, and silent cron

Use this reference when maintaining Semyon's low-noise Hermes cron watchdogs, especially checks around `/mnt/media` and Docker health.

## Context

The R2D2 system watchdog is a Hermes cron `no_agent=true` job. Script-only cron jobs should:

- print **nothing** when healthy, so delivery stays silent
- print a concise alert when something is wrong
- exit non-zero only for genuinely broken script/runtime failures
- wrap all potentially blocking probes with `timeout`

This kind of watchdog is usually better as bash than Python when it mostly shells out to `df`, `findmnt`, `docker`, `awk`, etc. Bash keeps the script close to the system probes and avoids Python filesystem calls accidentally blocking on NFS.

## NFS pitfall

Avoid direct Python filesystem probes against `/mnt/media`, including:

```python
Path('/mnt/media').exists()
shutil.disk_usage('/mnt/media')
```

On stale or slow NFS, those calls can hang long enough for Hermes cron to kill the whole script. Instead:

```bash
timeout 5s findmnt -rn /mnt/media
timeout 8s df -P -B1 /mnt/media
```

If either times out or fails, emit a concise alert such as:

```text
R2D2 watchdog alert:
- /mnt/media disk check failed or timed out: ...
```

## Bash watchdog pattern

Skeleton:

```bash
#!/usr/bin/env bash
set -u
alerts=()

add_alert() { alerts+=("$1"); }

check_nfs() {
  local out lower
  if ! out="$(timeout 5s findmnt -rn /mnt/media 2>&1)"; then
    add_alert "/mnt/media is not mounted"
    return 1
  fi
  lower="${out,,}"
  if [[ "$out" != *"10.0.0.6:/nas"* && "$lower" != *" nfs"* ]]; then
    add_alert "/mnt/media mounted unexpectedly: ${out:0:160}"
    return 1
  fi
  return 0
}

check_docker() {
  command -v docker >/dev/null 2>&1 || return
  if ! timeout 12s docker info >/dev/null 2>&1; then
    add_alert "Docker daemon not responding"
    return
  fi
  local unhealthy
  unhealthy="$(timeout 12s docker ps --filter health=unhealthy --format '{{.Names}}' 2>/dev/null | awk 'NF { names[++n]=$0 } END { for (i=1; i<=n && i<=10; i++) printf "%s%s", (i>1 ? ", " : ""), names[i] }')"
  [[ -n "$unhealthy" ]] && add_alert "unhealthy Docker containers: $unhealthy"
}

# checks...

if (( ${#alerts[@]} > 0 )); then
  printf 'R2D2 watchdog alert:\n'
  for alert in "${alerts[@]}"; do
    printf -- '- %s\n' "$alert"
  done
fi
```

## Cron update workflow

When converting a Hermes script-only cron job from Python to bash:

1. Write the bash script under `~/.hermes/scripts/<name>.sh`.
2. `chmod 700 ~/.hermes/scripts/<name>.sh`.
3. Validate syntax and behaviour:
   ```bash
   bash -n ~/.hermes/scripts/<name>.sh
   timeout 130s ~/.hermes/scripts/<name>.sh
   ```
   Healthy output should be empty and exit code should be `0`.
4. Update the cron job script reference with the cron tool/CLI, not by hand-editing JSON when avoidable:
   ```text
   cronjob(action="update", job_id="...", script="<name>.sh")
   ```
5. Trigger a run and verify cron recorded `ok` and `silent (empty output)` when healthy.
6. Archive the old Python script as `.py.bak` if useful, then remove stale `__pycache__` so no active Python cron scripts remain.

## Verification commands

```bash
hermes cron list
find ~/.hermes/scripts -maxdepth 1 -type f -printf '%f %m %s bytes\n' | sort
python3 - <<'PY'
from pathlib import Path
base=Path.home()/'.hermes/cron/output/<job_id>'
for p in sorted(base.glob('*.md'), key=lambda p:p.stat().st_mtime, reverse=True)[:3]:
    print('---', p.name)
    print(p.read_text()[:400])
PY
```

## Reporting style

For user-facing summaries, distinguish:

- **watchdog logic working**: real unhealthy containers were correctly reported
- **implementation bug**: timeout caused by brittle NFS probing
- **current state**: current Docker/mount/disk health after verification

Do not call a watchdog fixed until both direct execution and a cron-triggered run are verified.
