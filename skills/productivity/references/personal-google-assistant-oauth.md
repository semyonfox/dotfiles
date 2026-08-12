# Personal Google/Gmail/YouTube assistant OAuth pattern

Use this when Semyon wants Hermes to summarize personal Gmail, inspect Google account data, or pull YouTube channel/analytics data for consumer accounts such as `semyon.fox@gmail.com` or `foscopegaming@gmail.com`. Keep this separate from Workspace/GAM administration and from the Hermes Email gateway.

## Decision rule

- Consumer Gmail / personal Google account access: use OAuth installed-app user consent with a stored refresh token.
- Personal YouTube channel and YouTube Analytics access: also use OAuth installed-app user consent. YouTube Data/Analytics APIs do **not** support service accounts for channel/user data; service-account auth leads to `NoLinkedYouTubeAccount`-style failures.
- Google Workspace domain mail administered by Semyon: GAM can audit/configure users, groups, domains, DNS, and Workspace settings.
- A mailbox for talking *to* Hermes by email: use Hermes gateway Email adapter via IMAP/SMTP with a dedicated mailbox and allowlist.
- Service accounts are not the right default for consumer Gmail. They only work for Gmail data access when paired with Workspace domain-wide delegation inside a Workspace domain the user administers.

## Recommended local architecture

For Semyon's personal assistant workflows, use per-account labels and per-account authorized-user tokens:

```text
~/.hermes/google-personal/
  client_secret.json
  accounts/
    personal/token.json        # semyon.fox@gmail.com
    foscopegaming/token.json   # foscopegaming@gmail.com
```

Permissions:

```bash
mkdir -p ~/.hermes/google-personal/accounts
chmod 700 ~/.hermes/google-personal ~/.hermes/google-personal/accounts
chmod 600 ~/.hermes/google-personal/client_secret.json
chmod 600 ~/.hermes/google-personal/accounts/*/token.json
```

Install Google Cloud CLI via apt when the user asks for a system install:

```bash
sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo 'deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main' | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
sudo apt-get update
sudo apt-get install -y google-cloud-cli
```

Verify apt ownership, not just command presence:

```bash
dpkg -S /usr/bin/gcloud /usr/bin/gsutil /usr/bin/bq
gcloud --version
```

If a prior manual `~/.local/bin/gcloud`/`gsutil`/`bq` symlink shadows `/usr/bin`, remove only the shadowing symlink and re-check `command -v`.

## OAuth setup steps

1. Create/select a Google Cloud project.
2. Enable the APIs needed for the requested data:
   - Gmail API: `https://console.cloud.google.com/apis/library/gmail.googleapis.com`
   - YouTube Data API v3: `https://console.cloud.google.com/apis/library/youtube.googleapis.com`
   - YouTube Analytics API: `https://console.cloud.google.com/apis/library/youtubeanalytics.googleapis.com`
   - Calendar API: `https://console.cloud.google.com/apis/library/calendar-json.googleapis.com`
   - People API / Contacts: `https://console.cloud.google.com/apis/library/people.googleapis.com`
   - Drive API: `https://console.cloud.google.com/apis/library/drive.googleapis.com`
3. Configure OAuth consent: External is fine for consumer Gmail; add Semyon as test user if the app remains in Testing. Move to Production for long-lived refresh tokens where appropriate.
4. Create OAuth Client ID: Application type `Desktop app`.
5. Store the downloaded client secret as `~/.hermes/google-personal/client_secret.json` with `0600` permissions.
6. Run an installed-app OAuth flow once per account label and store `accounts/<label>/token.json`.

## Helper CLI pattern

A useful local helper is `google-auth-account` backed by a dedicated Python venv (`google-auth`, `google-auth-oauthlib`, `google-api-python-client`, `google-auth-httplib2`). It should support:

- `google-auth-account --list-scopes`
- `google-auth-account personal --all-scopes --no-browser`
- `google-auth-account foscopegaming --all-scopes --port 8766 --no-browser`
- `google-auth-account personal --allow-partial --no-browser` when Google grants fewer scopes and you need to save the partial token for inspection.

For remote/headless auth, match the local server port to an SSH tunnel:

```bash
ssh -L 8765:localhost:8765 semyon@HOST
google-auth-account personal --port 8765 --no-browser
```

If `OSError: [Errno 98] Address already in use`, do **not** treat auth as broken; rerun on a different port and forward that port if remote:

```bash
google-auth-account foscopegaming --port 8766 --no-browser
```

## Scope presets

Prefer least-dangerous scopes that still support the workflow, but Semyon may explicitly ask for broad Gmail/YouTube assistant access.

Baseline read-only:

- `https://www.googleapis.com/auth/gmail.readonly`
- `https://www.googleapis.com/auth/youtube.readonly`
- `https://www.googleapis.com/auth/yt-analytics.readonly`

Gmail management, only when requested:

- `https://www.googleapis.com/auth/gmail.modify`
- `https://www.googleapis.com/auth/gmail.send`
- `https://www.googleapis.com/auth/gmail.labels`
- `https://www.googleapis.com/auth/gmail.settings.basic`

YouTube management / analytics, only when requested:

- `https://www.googleapis.com/auth/youtube`
- `https://www.googleapis.com/auth/youtube.force-ssl`
- `https://www.googleapis.com/auth/youtube.upload`
- `https://www.googleapis.com/auth/yt-analytics-monetary.readonly`

Assistant context data:

- `openid`
- `https://www.googleapis.com/auth/userinfo.email`
- `https://www.googleapis.com/auth/userinfo.profile`
- `https://www.googleapis.com/auth/calendar.readonly`
- `https://www.googleapis.com/auth/contacts.readonly`
- `https://www.googleapis.com/auth/drive.metadata.readonly`

Avoid full Drive file-content scopes and full Gmail `https://mail.google.com/` unless Semyon explicitly asks; those are high-blast-radius scopes.

## OAuth partial-scope pitfall

Google can return fewer scopes than requested. `requests-oauthlib` may then raise a warning-as-exception like:

```text
Warning: Scope has changed from "...gmail.readonly ...youtube.readonly ...yt-analytics.readonly" to "...gmail.readonly".
```

This usually means the user/account/consent screen only granted a subset, or a needed API/scope is not configured/accepted. Good handling:

1. Tell Semyon exactly which scopes were requested and which were granted.
2. Check the relevant APIs are enabled in the selected Cloud project.
3. Ask him to re-run the auth flow and tick/allow every permission.
4. If needed, set `OAUTHLIB_RELAX_TOKEN_SCOPE=1` or provide an `--allow-partial` mode to save the partial token, then inspect granted scopes before using the token.

## Verification checklist

- `gcloud`/`gsutil`/`bq` resolve to apt-owned `/usr/bin/*` when the user asked for apt install.
- OAuth client exists at the expected path and token files exist per account label.
- `gmail-whoami <label>` returns the expected Gmail account before reading data.
- `yt-channel-stats <label>` returns the expected channel title/ID before pulling analytics.
- `yt-analytics-last <label> <CHANNEL_ID>` returns rows for the intended channel/date range.
- Gmail queries return metadata only unless full-message content is necessary.
- Draft/send/modify scopes are not used unless Semyon explicitly granted that workflow.
- Any cron job using this should fail loudly when `token.json` is missing, not silently produce an empty briefing.

## Pitfalls

- Do not conflate stale Workspace accounts (e.g. old `oghmanotes.ie` admin setup) with Semyon's current consumer Google accounts.
- Do not recommend a service account for consumer Gmail or personal YouTube access.
- Do not configure Hermes Email gateway as the mechanism for summarizing an inbox; it is a messaging surface, not an inbox-analysis integration.
- Keep OAuth client secrets and tokens out of conversation output and under restrictive file permissions.
- If a localhost OAuth flow fails, check port listeners/processes and retry a different port before changing credentials or scopes.
