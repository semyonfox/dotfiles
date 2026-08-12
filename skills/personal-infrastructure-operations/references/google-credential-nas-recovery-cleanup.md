# Google credential NAS recovery and cleanup

Use this when Semyon asks to find, recover, centralize, or clean up Google/Gmail/GAM/Gemini/Firebase credentials from NAS/device backups.

## Credential classes must stay separate

Do not merge all Google-looking files into one directory. Classify by purpose first:

- `~/.gam/` — GAM / Google Workspace admin and domain-wide delegation only.
- `~/.config/gcloud/` — `gcloud` CLI state only.
- `~/.gemini/` — Gemini / Antigravity CLI auth only. The nested path `~/.gemini/.gemini/oauth_creds.json` can be legitimate; verify existing layout before “fixing” it.
- `~/.hermes/google-personal/` — personal Gmail/Calendar OAuth client and token for Hermes workflows.
- `~/secrets/google/firebase/<project>/` — Firebase / Google service-account keys that apps consume explicitly.

Consumer Gmail is not the same thing as GAM Workspace mail. Gemini `cloud-platform`/`userinfo` OAuth tokens are not Gmail API tokens. OAuth client secrets are not authorized tokens.

## Safe search pattern

Search current server plus `/mnt/media/users/semyon/device_dumps` and similar NAS roots for Google credential candidates, but avoid full blind recursive scans over huge media/cache trees when possible. Target filenames and known config directories:

- `client_secret*.json`
- `application_default_credentials.json`
- `oauth2*.json`, `oauth2*.txt`, `oauth*.json`, `oauth*.txt`
- `oauth_creds.json`
- `token.json`, `credentials.json`
- `gam.cfg`, `oauth2service.json`
- `serviceAccountKey.json`, `*firebase-adminsdk*.json`, `service*account*.json`
- `.gam/`, `.config/gcloud/`, `.gemini/`, `.credentials/`

Exclude noisy trees such as `node_modules`, `.git`, package-manager stores, caches, media, and generated logs unless the user explicitly wants an exhaustive forensic crawl.

## Inventory rules

Create a redacted inventory before copying or deleting anything. Record:

- path
- class/purpose
- size, mtime, SHA256
- duplicate count by hash
- safe metadata only: `project_id`, `client_id`, `client_email`, GAM section/domain/admin email, scope names

Never print or persist raw `refresh_token`, `access_token`, `client_secret`, `private_key`, app passwords, or service-account private keys in chat or reports.

## Migration workflow

1. Back up current server state first into a timestamped local bundle, e.g. `~/.credentials-cleanup-backups/google-YYYYMMDD-HHMMSS/` with `0700` permissions.
2. Back up exact NAS source files into the same bundle before deleting them.
3. Copy recovered files into the class-specific server locations above, with `0600` file permissions and `0700` parent dirs.
4. Verify source-to-destination hashes before any deletion.
5. Delete only exact migrated source files from NAS/backups, using a manifest/list. Do not delete broad backup directories.
6. Re-check that every listed source path is gone and every destination exists with sane owner/perms.

Prefer plain `cp` rather than `cp -a` when copying from NFS/device-dump paths into local secret stores; preserving ownership/mode from the NAS can fail or create wrong groups. Set owner and permissions explicitly after copying.

## Interpretation pitfalls

- `client_secret_*.json` is only an OAuth client definition; it does not grant account access until an OAuth consent flow creates an authorized-user token.
- `~/.gam/oauth2service.json.empty-*` or service-account-shaped JSON with no `private_key` is a placeholder, not a usable service-account key.
- GAM may have admin OAuth but still fail Gmail labels/messages until service account + domain-wide delegation are repaired.
- Firebase service-account keys found in repos/backups should usually be rotated after consolidation, especially if they were ever committed or widely copied.
- Remaining `firebase.json` files are usually project config, not secret credentials.

## Post-migration verification

Report concrete paths and permissions, not secret values. State what still requires installed binaries or fresh login, e.g. Gmail OAuth flow, GAM install/repair, gcloud install/reauth, Firebase key rotation.
