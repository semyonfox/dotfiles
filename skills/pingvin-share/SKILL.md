---
name: pingvin-share
description: Use when the user asks to upload or share a file or app build, or wants a download link.

metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
---

# Pingvin Share

Use `https://fileshare.semyon.ie` (Pingvin Share X on `server`). Tell the user
the link is public and to share it carefully.

1. Check the file or archive for obvious credentials or private data. Stop if
   it should not be public. For an app build, verify the build's source revision,
   package ID, version, and signing identity before replacing an existing share;
   a filename or an old download is not proof of a new build.
2. On `server`, use `python3 /home/semyon/server-stacks/fileshare/publish-file.py --expires-days N FILE`.
   For a new version, add `--replace-share ID` to keep its link. Find app
   share IDs in `fileshare/README.md`; only create a new share when needed or
   asked. Transfer the file to `server` first if needed. `--dry-run` prints the
   URLs without publishing.
3. The command prints JSON with `sha256`, `share_url` and `download_url`. For a
   build, download `download_url` and compare its checksum with the verified
   original. If the new build cannot be produced or verified, leave the current
   share intact.
4. Return the link and expiry. Confirm that a replacement kept the same link
   and now serves the new file.

For Android APKs, give `https://fileshare.semyon.ie/app.apk.php?share=<share-id>`
(or the saved URL in `fileshare/README.md`). It sends the APK MIME type and
supports range downloads; check for a `206` response to `Range: bytes=0-0`. It
only works for public, passwordless shares. The `.php` name is historical,
nginx serves it and there is no PHP.
