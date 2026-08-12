# Personal Google OAuth CLI pattern

Use this when Semyon asks whether Hermes can access personal Gmail, Google accounts, YouTube channels, or YouTube Analytics from CLI/cron jobs.

## Durable auth facts

- Personal Gmail and normal YouTube channel/private analytics access should use OAuth 2.0 with `access_type=offline` and a stored refresh token.
- Service accounts are not a good fit for personal Gmail/YouTube. Gmail service-account impersonation requires Google Workspace domain-wide delegation. YouTube Data/Analytics/Reporting APIs do not support service accounts for private channel/user data; attempts can fail with `NoLinkedYouTubeAccount` because a service account cannot be linked to a YouTube channel.
- A one-time browser consent flow per Google identity/channel-owner account is normal. After that, CLI scripts can refresh access tokens automatically from the saved refresh token.
- If the OAuth consent app stays in Google Cloud “Testing” mode, refresh tokens may expire inconveniently. For long-lived personal automation, publish the app “In production” even if it remains private/unverified and only Semyon uses it.

## Preferred local layout

```text
~/.hermes/google-personal/
  client_secret.json          # Desktop OAuth client, chmod 600
  accounts/
    personal/token.json       # OAuth refresh token, chmod 600
    youtube-gaming/token.json
```

Use labels for Google identities, not channel names, when that is clearer: `personal`, `youtube-gaming`, `brand-account-owner`, etc. Current preferred labels for Semyon are:

```text
personal       -> semyon.fox@gmail.com
foscopegaming  -> foscopegaming@gmail.com
```

Treat old Workspace/GAM state for `semyon@oghmanotes.ie` as stale unless Semyon explicitly asks to operate on legacy OghmaNotes Workspace admin resources.

## Minimal scopes to start

Start read-only; add write/send scopes only when Semyon explicitly asks.

```text
https://www.googleapis.com/auth/gmail.readonly
https://www.googleapis.com/auth/youtube.readonly
https://www.googleapis.com/auth/yt-analytics.readonly
```

Optional later:

```text
https://www.googleapis.com/auth/gmail.send
https://www.googleapis.com/auth/gmail.modify
https://www.googleapis.com/auth/yt-analytics-monetary.readonly
```

## Discovery workflow

1. Check existing CLI readiness and credentials without printing secrets:
   - binaries: `gcloud`, `gam`, `oauth2l`, `rclone`, `python3`
   - credential directories: `~/.config/gcloud`, `~/.gam`, `~/.hermes/google-personal`, `~/.config/rclone/rclone.conf`
   - only report metadata: file existence, permissions, account IDs/emails, scopes, token expiry; never dump token/client-secret content.
2. If GAM exists, distinguish Workspace admin capability from personal Gmail/YouTube capability. GAM auth for a Workspace admin account does not imply personal Gmail/YouTube Analytics access.
3. Inspect OAuth scopes. If Gmail/YouTube scopes are absent, re-auth/create a separate token with the required scopes rather than claiming the existing credential works.
4. Prefer small Python CLI wrappers using `google-auth-oauthlib`, `google-auth`, and `google-api-python-client`. Hermes can call those scripts from terminal, cron, or future MCP/custom tools.
5. If Google libraries/CLIs are missing, install Python helper libraries into a dedicated user-local environment rather than mutating Hermes' internal venv. A good default is `~/.local/venvs/google-api` for Python helpers.
6. For `gcloud`/`gsutil`/`bq`, respect Semyon's preference for native package-manager installs when he asks for it. On Ubuntu/Debian, prefer the official Google Cloud apt repository and package `google-cloud-cli` over a tarball/user-local SDK. After apt install, remove any `~/.local/bin/{gcloud,gsutil,bq}` symlinks that shadow `/usr/bin` so future commands use the apt-owned binaries.
7. Do not pipe a password into `sudo -S`, even if Semyon supplies one in chat. If privileged apt work is explicitly requested, use an interactive PTY sudo flow (`terminal(..., pty=true)` and answer the prompt) or ask Semyon to run the command himself. Avoid recording the password in scripts, files, env vars, or command history.

## Apt install pattern for Google Cloud CLI

Use this when Semyon asks for a “proper apt install” rather than a user-local tarball:

```bash
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg.tmp
sudo mv /usr/share/keyrings/cloud.google.gpg.tmp /usr/share/keyrings/cloud.google.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' \
  | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
sudo apt-get update
sudo apt-get install -y google-cloud-cli
```

Verify package ownership and resolution:

```bash
dpkg -S /usr/bin/gcloud /usr/bin/gsutil /usr/bin/bq
dpkg -l google-cloud-cli
apt-cache policy google-cloud-cli
command -v gcloud gsutil bq
gcloud --version
```

If a prior user-local SDK was installed, remove only shadowing symlinks first:

```bash
for f in ~/.local/bin/gcloud ~/.local/bin/gsutil ~/.local/bin/bq; do
  if [ -L "$f" ] && readlink "$f" | grep -q "$HOME/.local/opt/google-cloud-sdk/bin"; then
    rm "$f"
  fi
done
hash -r
```

Do not automatically delete `~/.local/opt/google-cloud-sdk`; report its size and ask before removing the directory.

## User-local Python helper install pattern

Python helper environment:

```bash
python3 -m venv ~/.local/venvs/google-api
~/.local/venvs/google-api/bin/python -m pip install --upgrade pip setuptools wheel
~/.local/venvs/google-api/bin/python -m pip install --upgrade \
  google-auth \
  google-auth-oauthlib \
  google-api-python-client \
  google-auth-httplib2
```

Google Cloud CLI without sudo:

```bash
mkdir -p ~/.local/opt ~/.local/bin
cd ~/.local/opt
curl -fL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz -o google-cloud-cli-linux-x86_64.tar.gz
tar -xzf google-cloud-cli-linux-x86_64.tar.gz
./google-cloud-sdk/install.sh --quiet --usage-reporting=false --path-update=false --command-completion=false
ln -sf ~/.local/opt/google-cloud-sdk/bin/gcloud ~/.local/bin/gcloud
ln -sf ~/.local/opt/google-cloud-sdk/bin/gsutil ~/.local/bin/gsutil
ln -sf ~/.local/opt/google-cloud-sdk/bin/bq ~/.local/bin/bq
```

Install helper scripts with shebang `#!/home/semyon/.local/venvs/google-api/bin/python` and link them into `~/.local/bin`. Verify with `--help` and import/version checks before claiming they are ready.

## Token generation script shape

Use an installed-app/desktop OAuth client and save one token per account label:

```python
from pathlib import Path
from google_auth_oauthlib.flow import InstalledAppFlow

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
    "https://www.googleapis.com/auth/youtube.readonly",
    "https://www.googleapis.com/auth/yt-analytics.readonly",
]

base = Path.home() / ".hermes" / "google-personal"
flow = InstalledAppFlow.from_client_secrets_file(str(base / "client_secret.json"), SCOPES)
creds = flow.run_local_server(port=0, access_type="offline", prompt="consent")
token_path = base / "accounts" / account_label / "token.json"
token_path.parent.mkdir(parents=True, exist_ok=True)
token_path.write_text(creds.to_json())
token_path.chmod(0o600)
```

## Verification probes

After auth, verify each capability with a harmless read-only call:

- Gmail: `gmail.users().getProfile(userId="me")`
- YouTube Data API: `youtube.channels().list(part="snippet,statistics,contentDetails", mine=True)`
- YouTube Analytics API: `youtubeAnalytics.reports().query(ids=f"channel=={channel_id}", startDate=..., endDate=..., metrics="views,estimatedMinutesWatched", dimensions="day")`

Common results:

- `accessNotConfigured`: enable the API in the Google Cloud project.
- `insufficientPermissions`: token lacks scopes; delete/recreate that account token with the needed scope.
- no channel returned for `mine=True`: authenticated Google identity does not own/have access to a YouTube channel.
- Analytics permission error: wrong channel/account, missing analytics scope, or channel not eligible/exposed for that report.

## Safety defaults

- Never ask Semyon to paste token files, client secrets, or refresh tokens into chat.
- Keep files under `~/.hermes/google-personal` mode `700` for directories and `600` for secrets/tokens.
- For email sending, uploads, comment moderation, deletion, or channel-management scopes, confirm intent and exact scope before authorizing or running write operations.
