---
name: erugo-share
description: Use when the user asks to upload or share a file or app build, or wants a download link.

metadata:
  harnesses: [claude, codex, opencode, cursor, gemini, hermes]
---

# Erugo

Use `https://fileshare.semyon.ie`. Tell the user the link is public and to share
it carefully.

1. Check the file or archive for obvious credentials or private data. Stop if
   it should not be public. For an app build, verify the build's source revision,
   package ID, version, and signing identity before replacing an existing share;
   a filename or an old download is not proof of a new build.
2. On `server`, use `python3 /home/semyon/server-stacks/fileshare/publish-file.py --expires-days N FILE`.
   For a new version, add `--replace-share SLUG` to keep its link. Find app
   slugs in `fileshare/README.md`; only create a new share when needed or asked.
   Transfer the file to `server` first if needed.
3. Check the filename, size, and expiry at `/api/shares/<share-id>`. For a
   build, download it and compare its checksum with the verified original. If
   the new build cannot be produced or verified, leave the current share intact.
4. Return the link and expiry. Confirm that a replacement kept the same link
   and now serves the new file.

For Android APKs, use the saved URL in `fileshare/README.md`, or
`https://fileshare.semyon.ie/app.apk.php?share=<share-id>` for another public,
passwordless, single-file share. Erugo's normal route sends APKs
as `application/zip`; this link sends the APK MIME type and supports range
downloads. Check for a `206` response to `Range: bytes=0-0`. Do not use this
route for password-protected shares.
