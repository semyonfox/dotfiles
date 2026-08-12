---
name: discord-file-delivery
description: "Use when deliver files from Hermes to Discord reliably, including MEDIA tags, upload size limits, and fallback links for large artifacts."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos]

metadata:
  harness: [hermes]
---

# Discord File Delivery from Hermes

Use when the user asks to send/upload/attach a file in a Discord conversation, especially build artifacts such as APKs, ZIPs, PDFs, videos, or reports.

## Ground truth

Hermes Discord supports native uploads through inline tags in a message:

```text
MEDIA:/absolute/path/to/file
```

The Discord adapter strips the tag and uploads the file as a native attachment. Documents such as APK/ZIP/PDF are sent as downloadable file attachments.

## Critical limit

Discord enforces a per-upload size cap depending on the server boost tier. Common free limit is **25 MB**. Hermes logs show Discord rejects oversized uploads with:

```text
413 Payload Too Large (error code: 40005): Request entity too large
```

When this happens, repeating `MEDIA:/path` will not help. The file is too large for that Discord surface.

Check logs if delivery appears to silently fail:

```bash
grep -R "413\|Payload Too Large\|Failed to send document\|MEDIA:" -n ~/.hermes/logs ~/.hermes/sessions 2>/dev/null | tail -80
```

## Workflow

1. Resolve the user's intended scope before attaching files. If the request is a follow-up like “send all the SVGs/PDFs” after discussing rendered artifacts, prefer the previously identified artifact directories rather than a repo-wide extension sweep. Avoid surprising attachments such as reports, test fixtures, sample papers, dependency assets, or build junk unless the user explicitly asked for every matching extension in the whole repo.

2. Verify the file exists and size:

```bash
ls -lh /absolute/path/to/file
sha256sum /absolute/path/to/file
```

3. If file is safely below the likely Discord limit, send it with either:

Final response:

```text
MEDIA:/absolute/path/to/file
```

or `send_message`:

```text
MEDIA:/absolute/path/to/file
```

3. If the target is a specific channel/thread, call `send_message(action="list")` first, then send to the exact target string from the list.

4. If upload fails with HTTP 413 or the file is clearly too large:
   - Do **not** keep retrying the attachment.
   - For Semyon's own large artifacts, prefer the self-hosted Erugo fileshare (`https://fileshare.semyon.ie`) before public temporary hosts. The detailed Erugo workflow lives in `personal-infrastructure-operations` → `references/erugo-fileshare-artifact-delivery.md`.
   - Upload to a public temporary/direct file host only if the user requested upload/delivery, Erugo/self-hosted delivery is unavailable, and the artifact is not sensitive.
   - Verify the download URL with `curl -I` and include the SHA256.
   - Tell the user Discord rejected the native upload because of size.

Example public temporary host fallback:

```bash
APK=/path/to/file.apk
out=$(curl --fail --silent --show-error -F "file=@${APK}" https://tmpfiles.org/api/v1/upload)
echo "$out"
# Convert https://tmpfiles.org/<id>/<file> to https://tmpfiles.org/dl/<id>/<file>
curl -I --fail "https://tmpfiles.org/dl/<id>/<file>"
sha256sum "$APK"
```

## Multi-file asset delivery

When Semyon asks for many project assets “here in Discord”:

- Respect the requested extensions exactly. Do not broaden “PNGs” into PDFs/SVGs or “SVGs” into repo PDFs unless he explicitly asks for those formats.
- “Don’t bundle them” means send individual `MEDIA:` attachments, not ZIP/tar archives. Split into multiple messages if needed; keep batches small enough for Discord/Hermes reliability (around 5–10 attachments per message worked well for many small PNG/SVG assets).
- Prune obvious generated-noise assets unless explicitly requested: coverage-report favicons, sort-arrow sprites, dependency/build/cache output. Prefer human-facing rendered assets such as `screenshots/`, `diagrams/rendered/`, and app `public/` images.
- If using `send_message`, verify each batch returns `success: true` and keep going until all batches have a message ID.

## Notes

- Prefer native Discord attachment when possible.
- When Semyon explicitly asks for many files “not bundled” / “as attachments,” send them as individual `MEDIA:` tags split across several Discord messages rather than a ZIP/tarball. Keep batches modest (around 5–10 files per message) so Discord/Hermes can upload reliably, and verify each `send_message` result before claiming delivery.
- For broad extension requests like “all SVGs/PDFs/PNGs,” inspect the file list first and avoid generated junk (coverage icons, dependency/build assets) unless the user truly wants every file. If an extension includes likely fixtures or reports, mention that they were included because of the literal extension filter and be ready to narrow the set.
- When the user asks for “all PNGs/SVGs/PDFs” from a project after discussing rendered artifacts, scope the search to the likely artifact directories first (`diagrams/rendered`, `screenshots`, `public` when relevant) and prune dependency/build/test-output junk (`node_modules`, `.git`, `dist`, `build`, `.next`, `coverage`). Do not blindly include reports, fixture PDFs, favicons, or coverage sprites unless the user explicitly wants every matching extension in the repo.
- If “don’t bundle them” is explicit, send multiple Discord messages with several `MEDIA:` lines each; that still produces separate native attachments while avoiding a zip/tar archive.
- For large batches, report count and any deliberate exclusions plainly after sending, not before asking for confirmation unless the scope is genuinely ambiguous.
- For large APKs/build artifacts, a direct download link plus checksum is usually the practical path.
- For large APKs/build artifacts, a direct download link plus checksum is usually the practical path.
- For large APKs/build artifacts, a direct download link plus checksum is usually the practical path.
- On Semyon's infrastructure, prefer the self-hosted Erugo fileshare at `fileshare.semyon.ie` when available. It lives under `/home/semyon/server-stacks/fileshare/` and can handle large APK-style artifacts better than Discord's native cap.
- When the user needs to tap a URL from Discord/mobile, put the URL as a bare clickable line, not inside a code block.
- For APKs, remember APKs are ZIP containers; if Android/file managers treat the download as a ZIP/folder, serve it with `Content-Type: application/vnd.android.package-archive` and `Content-Disposition: attachment; filename="name.apk"`, or stage it via ADB.
- Do not upload private or sensitive files to public temporary hosts without explicit user approval; use self-hosted Erugo first when possible.
- If using `send_message`, verify tool result includes `success: true`, platform `discord`, and a `message_id` before claiming delivery.
