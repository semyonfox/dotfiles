# Google personal OAuth, Gmail/YouTube CLI, and Helium-assisted console work

Use when Semyon wants Hermes/CLI access to personal Gmail/YouTube/Google data for `semyon.fox@gmail.com` and `foxscopegaming@gmail.com`.

## Account model and durable constraints

- Personal Gmail/YouTube accounts should use OAuth refresh tokens, not service accounts.
- YouTube Data/Analytics APIs do not support service-account access to normal personal channels; expect `NoLinkedYouTubeAccount` if trying that route.
- Workspace/GAM credentials for stale Workspace accounts are not proof that personal Gmail/YouTube access works.
- Keep token files private: report labels, scopes, email addresses, counts, and API status; never paste refresh tokens/client secrets.

Recommended labels:

```text
personal       -> semyon.fox@gmail.com
foxscopegaming -> foxscopegaming@gmail.com
```

## Known-good local layout

```text
~/.hermes/google-personal/
  client_secret.json                 # desktop OAuth client
  accounts/<label>/token.json        # OAuth refresh token, mode 0600
~/.local/venvs/google-api/            # dedicated Python venv
~/bin/google-auth-account
~/bin/gmail-whoami
~/bin/yt-channel-stats
~/bin/yt-analytics-last
```

Install libraries into a dedicated venv rather than Hermes' internal venv:

```bash
/usr/bin/python3 -m venv ~/.local/venvs/google-api
~/.local/venvs/google-api/bin/python -m pip install --upgrade pip setuptools wheel
~/.local/venvs/google-api/bin/python -m pip install --upgrade \
  google-auth google-auth-oauthlib google-api-python-client google-auth-httplib2
```

For `gcloud`, Semyon prefers a real apt install when possible:

```bash
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
printf '%s\n' 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
sudo apt-get update
sudo apt-get install -y google-cloud-cli
```

Verify apt ownership, not just `PATH`:

```bash
dpkg -S /usr/bin/gcloud /usr/bin/gsutil /usr/bin/bq
gcloud --version
```

## OAuth helper behavior

The auth helper should support scope presets and a partial-token escape hatch:

- `--all-scopes` for Gmail management + YouTube management/analytics + profile/calendar/contacts/Drive metadata.
- `--allow-partial` sets/uses `OAUTHLIB_RELAX_TOKEN_SCOPE=1` so a token can be saved when Google grants fewer scopes than requested. Use this to inspect what Google actually granted; do not pretend missing scopes work.
- If the callback port is busy, rerun with a different `--port` and forward that same port if remote.

Typical commands:

```bash
google-auth-account personal --all-scopes --no-browser
google-auth-account foxscopegaming --all-scopes --no-browser
# If remote/headless:
ssh -L 8765:localhost:8765 semyon@server
```

Safe probes:

```bash
gmail-whoami personal
gmail-whoami foxscopegaming
yt-channel-stats foxscopegaming
yt-analytics-last foxscopegaming CHANNEL_ID --days 28
```

## Google Cloud/API gotchas

If Gmail works but YouTube returns `accessNotConfigured` / `YouTube Data API v3 has not been used in project ... or it is disabled`, the OAuth token/scopes may be fine; the Cloud project behind the OAuth client is blocking the API.

Inspect the OAuth client metadata without secrets:

```bash
python3 - <<'PY'
import json, pathlib
p=pathlib.Path.home()/'.hermes/google-personal/client_secret.json'
cfg=json.loads(p.read_text()).get('installed') or {}
for k in ['client_id','project_id','auth_uri','token_uri','redirect_uris']:
    print(k, cfg.get(k))
PY
```

Then enable/check APIs on the exact project from the client, not whichever project the browser happened to select:

```text
https://console.cloud.google.com/apis/library/youtube.googleapis.com?project=<project_id>
https://console.cloud.google.com/apis/library/youtubeanalytics.googleapis.com?project=<project_id>
https://console.cloud.google.com/apis/library/youtubereporting.googleapis.com?project=<project_id>
https://console.cloud.google.com/apis/credentials?project=<project_id>
```

After enabling, wait a few minutes and retry the live probe. Distinguish propagation delay from wrong-project selection.

## Using Semyon's PC Helium browser over SSH

When the signed-in desktop browser is needed, probe `pc` first:

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 pc 'hostname; command -v helium-browser; pgrep -a helium | head'
```

For Hyprland GUI control over SSH, export the live Wayland/Hyprland env:

```bash
export XDG_RUNTIME_DIR=/run/user/$(id -u)
export WAYLAND_DISPLAY=wayland-1
export HYPRLAND_INSTANCE_SIGNATURE=$(ls "$XDG_RUNTIME_DIR/hypr" | head -1)
```

Useful checks/actions on `pc`:

```bash
hyprctl activewindow -j
hyprctl dispatch exec 'helium-browser https://console.cloud.google.com/...'
grim /tmp/hermes-pc-screen.png
wtype 'text to type'
```

If `grim` says `failed to create display`, `WAYLAND_DISPLAY` was probably missing; on Semyon's PC it was `wayland-1`.

Do not blindly click through Google account/security/payment prompts. Open pages and guide/confirm visible actions unless Semyon has explicitly requested a precise safe click such as `click Enable if visible`.
