# Fileshare artifact delivery

Use when Discord/native chat upload limits reject a large artifact, or when Semyon asks for a self-hosted download link.

Erugo was replaced by Pingvin Share X on 2026-10-22. The file keeps its old name so existing links to it still resolve. Do not write into `legacy-storage/` (the old Erugo storage, kept as a read-only archive) or the old Erugo database.

## Service facts

- Stack: `/home/semyon/server-stacks/fileshare/` (see its `README.md`)
- App: Pingvin Share X (`pingvin-share-x`) behind nginx (`pingvin-web`, host port 3003), Cloudflare Tunnel at `https://fileshare.semyon.ie`
- Publisher: `/home/semyon/server-stacks/fileshare/publish-file.py`, signs in with `pingvin-admin.env`; never print that file

## Publish a file

```bash
python3 /home/semyon/server-stacks/fileshare/publish-file.py --expires-days 7 /path/to/file
```

It creates a public, passwordless, single-file share, checks the stored SHA-256, and prints JSON with `sha256`, `share_url` and `download_url`. `--dry-run` prints the URLs without publishing.

For a new version of something that already has a link, keep the link:

```bash
python3 /home/semyon/server-stacks/fileshare/publish-file.py --expires-days 365 --replace-share <share-id> /path/to/new.apk
```

The replacement must have the same extension. The previous file is kept in `version-backups/<share-id>/`. Saved app share ids are listed in the stack `README.md`.

## Android APKs

APKs are ZIP files, so a generic download can arrive as `application/zip` and Android sends it to an extractor. Give the nginx route instead, it sets `application/vnd.android.package-archive` and supports byte ranges:

```text
https://fileshare.semyon.ie/app.apk.php?share=<share-id>
```

The `.php` name is historical, nginx serves it and there is no PHP. `/t3-apk.php` and `/network-rush.apk.php` are fixed aliases for the T3 Code and Network Rush shares.

## Verification

Always download the public URL into a temp directory and compare it with the source:

```bash
tmp=$(mktemp -d)
curl -fsSL -o "$tmp/download" '<download_url>'
sha256sum "$tmp/download"      # must equal the sha256 printed by publish-file.py
curl -s -o /dev/null -w '%{http_code}\n' -r 0-0 '<download_url>'   # APKs: expect 206
rm -rf "$tmp"
```

## Admin login

Credentials are in `pingvin-admin.env` (mode 0600). Do not print or paste them. Open registration is off.

## User-facing install guidance for APKs

- Open the direct `.apk` link on Android.
- If the file manager says ZIP, do **not** extract it.
- Rename the downloaded file to `.apk` if necessary.
- Open with Android Package Installer.
- Allow “Install unknown apps” for the browser/files app if prompted.
- If updating fails, uninstall the old preview app first; mismatched debug signing can block updates.
