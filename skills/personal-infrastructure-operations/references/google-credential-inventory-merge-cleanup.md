# Google credential inventory and cleanup from NAS/device dumps

Use when Semyon asks to recover/clean Google, Gmail, GAM, Gemini, gcloud, Firebase, or Workspace credentials from current server state plus NAS backups under `/mnt/media/users/semyon/`.

## Scope distinction

Keep Google auth material separated by purpose; do not merge everything into one credential drawer:

```text
~/.gam/                                  # Google Workspace / GAM only
~/.config/gcloud/                         # gcloud CLI only
~/.gemini/                                # Gemini / Antigravity only
~/.hermes/google-personal/                # personal Gmail/Calendar OAuth for Hermes workflows
~/secrets/google/firebase/<project>/       # Firebase service-account keys, if still needed
```

Important distinctions:

- Consumer Gmail needs Gmail API OAuth or IMAP/app-password. GAM is not for consumer `@gmail.com` inboxes.
- GAM Workspace user-data access needs a valid service-account key plus domain-wide delegation; an admin OAuth token alone is not enough.
- Gemini/Antigravity OAuth tokens often have `cloud-platform`/userinfo scopes, not Gmail scopes; do not reuse them as Gmail inbox access.
- Firebase Admin SDK service-account JSON files are private-key credentials. If found scattered in repos/backups, prefer key rotation over merely moving the file.

## Safe inventory workflow

1. Search current server config and NAS/device dumps, pruning dependency/cache/media trees:
   - current: `~/.gam`, `~/.config/gcloud`, `~/.gemini`, `~/.hermes/google-personal`
   - NAS: `/mnt/media/users/semyon/device_dumps/**`
   - filenames: `client_secret*.json`, `application_default_credentials.json`, `oauth2*.txt/json`, `oauth_creds.json`, `gam.cfg`, `oauth2service.json`, `serviceAccountKey.json`, `firebase-adminsdk*.json`, `firebase.json`
2. Generate a redacted inventory artifact, not a chat dump. Include path, class, mtime, size, hash prefix/full hash in file artifact, duplicate count, safe identity fields such as project ID/client ID/client email. Never print refresh tokens, client secrets, private keys, access tokens, or raw credential files.
3. Deduplicate by SHA-256. Treat snapshot copies as evidence; do not delete raw backups wholesale.
4. Verify current tool readiness separately: `command -v gam`, `command -v gcloud`, `gam showsections`, `gcloud auth list`, but do not infer working access from files alone.

## Merge/replace prep

Before any live replacement:

```bash
TS=$(date +%Y%m%d-%H%M%S)
mkdir -p ~/.credentials-cleanup-backups/google-$TS
cp -a ~/.gam ~/.credentials-cleanup-backups/google-$TS/gam 2>/dev/null || true
cp -a ~/.config/gcloud ~/.credentials-cleanup-backups/google-$TS/gcloud 2>/dev/null || true
cp -a ~/.gemini ~/.credentials-cleanup-backups/google-$TS/gemini 2>/dev/null || true
chmod -R go-rwx ~/.credentials-cleanup-backups/google-$TS
```

Then handle each class separately:

- **Personal Gmail/Hermes**: stage a recognized installed-app OAuth client as `~/.hermes/google-personal/client_secret.json`, then run a fresh OAuth consent flow for `gmail.readonly` and optionally `gmail.compose` (drafts). Do not use Gemini cloud-platform tokens for Gmail.
- **GAM/Workspace**: install/verify GAM, inspect `gam.cfg` sections, repair service-account/domain-wide delegation if `oauth2service.json` is missing/empty, and verify with `show labels` / `print messages max 10` for the target Workspace user.
- **gcloud**: if `gcloud` is absent or `credentials.db` has no usable account evidence, prefer clean install + fresh `gcloud auth login`/ADC over copying stale DBs.
- **Gemini/Antigravity**: only replace OAuth files from newer backups if the current CLI is broken/logged out; back up current first and verify with the actual CLI.
- **Firebase service accounts**: if still needed, relocate to a proper secret path or vault and rotate the key in Google Cloud/Firebase if it was scattered through repos/backups.

## Deletion/quarantine rule

Do not delete old credential files during inventory. After live access is verified and replacements/rotations are complete, delete only exact manifest-listed duplicates or move them to a timestamped quarantine. Service-account keys should be revoked/rotated before old copies are removed.