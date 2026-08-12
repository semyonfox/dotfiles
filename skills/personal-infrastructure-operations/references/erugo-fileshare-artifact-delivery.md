# Erugo fileshare artifact delivery

Use when Discord/native chat upload limits reject a large artifact, or when Semyon asks for a self-hosted SwissTransfer/Pingvin-style delivery path.

## Service facts

- Stack: `/home/semyon/server-stacks/fileshare/`
- App: Erugo (`erugo` container), fronted by Cloudflare Tunnel at `https://fileshare.semyon.ie`
- Local app: `http://localhost:3003`
- Public storage symlink: Erugo exposes files under `erugo-storage/app/public/` via `/storage/...`

## Important Android/APK pitfall

APKs are ZIP files internally. Erugo share downloads can return `Content-Type: application/zip` even when the attachment filename ends in `.apk`. On Android/Xiaomi/Google Files/CX File Explorer this can route the download to an extractor instead of Android Package Installer.

For APK delivery, prefer a static public-storage path instead of a share-download endpoint:

```bash
APK=/path/to/app.apk
mkdir -p /home/semyon/server-stacks/fileshare/erugo-storage/app/public/apk
cp "$APK" /home/semyon/server-stacks/fileshare/erugo-storage/app/public/apk/t3-code-preview.apk
chmod 0644 /home/semyon/server-stacks/fileshare/erugo-storage/app/public/apk/t3-code-preview.apk
```

Public URL:

```text
https://fileshare.semyon.ie/storage/apk/t3-code-preview.apk
```

Even if Cloudflare/Erugo still reports `application/zip`, the direct `.apk` filename makes Android handling more likely to work. Tell the user: do not extract it; rename to `.apk` if needed and open with Package Installer.

## Admin login/password recovery

Erugo lives at `/home/semyon/server-stacks/fileshare/` with the SQLite DB at `erugo-storage/app/private/database.sqlite`. The admin account is normally `semyon.fox@gmail.com`.

If Semyon asks whether he has the login or gives a desired password:

1. Inspect the `users` table without printing password hashes/secrets; confirm `admin=1` and `active=1`.
2. Back up the SQLite DB before changing credentials, e.g. `database.sqlite.before-password-reset-YYYYMMDD-HHMMSS`.
3. Generate a Laravel-compatible bcrypt hash using the running container's PHP `password_hash(..., PASSWORD_BCRYPT)` and update `users.password`, `must_change_password=0`, and `updated_at`.
4. Update `stack.env` with `ERUGO_ADMIN_EMAIL` / `ERUGO_ADMIN_PASSWORD`, chmod it `0600`, and do not paste the password back into chat if the user already supplied it in a public/thread context.
5. Verify two ways: Laravel `Hash::check`/`Auth::attempt` from inside the container, then a local API login POST to `http://127.0.0.1:3003/api/auth/login` with JSON `{email,password}` and require HTTP 200 plus `status=success` and an access token.

## Verification

Always verify by downloading the public URL into a temp directory, not just checking the local source file:

```bash
rm -rf /tmp/apk-direct-test && mkdir /tmp/apk-direct-test
cd /tmp/apk-direct-test
curl --fail --silent --show-error -LOJ 'https://fileshare.semyon.ie/storage/apk/t3-code-preview.apk'
file t3-code-preview.apk
sha256sum t3-code-preview.apk
cmp -s t3-code-preview.apk /path/to/local.apk && echo 'direct static APK matches local build'
```

For non-APK artifacts, Erugo normal shares are still fine. If using normal shares, verify with:

```bash
curl -I --fail --silent --show-error 'https://fileshare.semyon.ie/api/shares/<long-id>/download'
```

## User-facing install guidance for APKs

- Open the direct `.apk` link on Android.
- If the file manager says ZIP, do **not** extract it.
- Rename the downloaded file to `.apk` if necessary.
- Open with Android Package Installer.
- Allow “Install unknown apps” for the browser/files app if prompted.
- If updating fails, uninstall the old preview app first; mismatched debug signing can block updates.
