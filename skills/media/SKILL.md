---
name: media
description: "Use when finding, transforming, or delivering audio, video, image, or broadcast media and related listings."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Media Workflow

## Overview

Use this skill when the task is about media content rather than text or code: finding a GIF, checking what is on air, delivering a local image/audio/video file, or generally working with media artifacts that have to be discovered, packaged, or sent somewhere useful.

This umbrella focuses on media retrieval and delivery workflows. Creative generation is handled elsewhere; this skill is about moving and surfacing media cleanly.

## When to Use

- The user wants a GIF, broadcast listing, or similar media lookup
- The user wants to deliver or attach a local audio/video/image file
- The task is about media metadata, channels, or playback discovery rather than composition
- The user wants a local/NAS media library inspected, organized, deduplicated, or reported on
- You need to verify that a media file exists and can be sent in the expected format

## Core Media Families

### Search and discovery
Use these when the question is "find me the media":

- GIF search
- broadcast listings / what's airing now

### Delivery and attachment
Use these when the user already has a local file and wants it moved into a platform or message:

- local media delivery

### Local media library audit and cleanup
Use this when inspecting, organizing, deduplicating, or reporting on local NAS/media-server libraries:

- Start read-only: capacity, top-level usage, counts, duplicate candidates, and metadata checks before moving anything.
- For bulk cleanup, **move to a timestamped quarantine with a manifest** rather than deleting. Only permanently delete after explicit user approval.
- Do not rename top-level library roots casually; Jellyfin, *arr apps, torrent clients, and Docker bind mounts may depend on existing paths.
- For film dedupe, prefer actual probed resolution over filenames. Prefer 1080p-ish copies first; if no 1080p exists, prefer higher resolution over lower.
- Use local `.nfo` genre metadata when available to classify animation vs normal movies.
- See `references/nas-media-library-dedupe.md` for the Semyon NAS media-library workflow, including ffprobe scoring, NFO category checks, duplicate scans, and NAS `df` vs `du` caveats.

### OBS / DaVinci Resolve workflows

For cross-device Resolve project libraries, proxy/offline workflows, NAS media mounts, direct PC↔NAS editing links, and library-scoped collaborator access, see `references/resolve-project-library-and-nas-media-topology.md`. Keep Resolve's active Disk Database local; use NFS/SMB for active NAS media, reserve SFTP/GVFS mounts for browsing or occasional transfer, and use a dedicated PostgreSQL/Cloud library for shared project metadata.

### YouTube transcripts

When a user shares a YouTube link and asks to transcribe it, produce a **clean, downloadable Markdown transcript** rather than pasting a 30+ minute wall of text into chat. Include the source URL, channel/title, duration, timestamped sections (about 30 seconds is a good default), and a concise note that auto-generated captions can contain ASR errors.

1. Identify the video title and duration, then check whether captions are available.
2. Prefer the original-language automatic track where available (`en-orig` for English), not translated caption tracks.
3. With `yt-dlp`, request the target auto-caption track explicitly: `--skip-download --write-auto-subs --sub-langs en-orig --sub-format vtt`. Do not treat a broad `--list-subs` result that ends in “has no subtitles” as conclusive; a targeted automatic-caption download may still succeed.
4. Clean WebVTT's rolling/overlapping cues before delivery. Strip style/timing markup, deduplicate the overlap between adjacent cues, retain timestamps, and correct only unmistakable recurring ASR errors (for example, a product name consistently misheard throughout the video).
5. Verify the generated file has a title, timestamped content spanning the source duration, and no uncorrected instance of any deliberate normalization. Attach the `.md` file natively and state that it is complete.

Do not download the full video/audio merely to transcribe if YouTube’s caption track is available.

### YouTube transcription

When Semyon asks to transcribe a YouTube video, do **not** default to scraping or cleaning YouTube captions. First locate and inspect the local transcription project/service and its existing output conventions. Use its own YouTube downloader and ASR pipeline when available; captions are a fallback or comparison source only. Download audio into the project’s normal named output directory, transcribe with the project-selected model, and for long media keep the job tracked in the background while checking its incremental output. Do not report a transcript as complete until the project’s final artifact exists.

See `references/local-youtube-transcription-pipeline.md` for the current local pipeline, invocation shape, and verification checks.

### Practical handling
When you touch media, always confirm:

1. the source file exists
2. the format is acceptable to the destination
3. the delivery path preserves the content the user expects
4. any platform-specific quirks are handled before sending
5. for transcription, the final project-generated artifact exists before delivery

### Local/NAS media library cleanup

For library organization/dedupe tasks, especially under `/mnt/media/arrs`, use a conservative audit-first workflow:

1. Inspect capacity, top-level usage, library counts, duplicate title keys, and media metadata before moving anything.
2. Use `ffprobe` on the largest video file in each title folder to compare candidate duplicates.
3. Prefer 1080p-ish copies first; if no 1080p copy exists, prefer the higher resolution, then width/file size as tie-breakers.
4. Use `.nfo` metadata where present to classify animation vs live-action: `<genre>Animation</genre>` belongs in the animation/cartoons library; non-animation NFOs belong in movies.
5. Preserve existing library path names unless the user explicitly approves renaming; renaming `cartoons` to `animations` may break Jellyfin/*arr path mappings.
6. Move discarded duplicates to a timestamped quarantine with a manifest first. Delete only after explicit follow-up approval.
7. Verify active duplicate count and category mismatches are zero before reporting success.

See `references/local-media-library-dedupe.md` for the detailed dedupe workflow, scoring rules, and verification snippets.

### DaVinci Resolve, proxies, and NAS editing

For cross-device Resolve project libraries, proxy/offline workflows, NAS media mounts, or direct PC↔NAS editing links, keep the active Disk Database local, put originals/exports/backups on NAS, and distinguish a mounted folder from a real PostgreSQL/Cloud remote library. See `references/resolve-project-library-and-nas-media-topology.md`.

When consolidating legacy Resolve sources, make a namespaced, read-only staging archive with a README/manifest. Do not filesystem-merge Disk Database folders: import or restore projects into the chosen Network Project Library through Resolve. If stale library connections or disposable `New Project` sessions keep reopening, close Resolve normally before changing its saved `.dblist` connection list or `LastWorkingProject` setting; back up those files and remove only the unwanted entry. Do not kill Resolve merely to edit saved configuration unless the user explicitly accepts the risk to unsaved work.

### OBS capture and cross-platform editing archives

For OBS footage intended for DaVinci Resolve, prefer Hybrid MP4 on current OBS releases: it is crash-recoverable during recording and finalizes into a normal MP4, avoiding MKV/remux duplicates. When cleaning historical remux pairs, verify encoded stream hashes rather than trusting matching names. For safe Windows-to-Linux media migration, use namespaced destinations, checksum copy/verification, a removal manifest, and keep DaVinci project libraries separate from application caches. See `references/obs-hybrid-mp4-and-windows-media-migration.md`.

### OBS, DaVinci, and multi-device production media

When Semyon asks about OBS recordings, Resolve projects, remux duplicates, or where footage lives across PC/server/NAS, use a read-only cross-device inventory first. Treat server NFS mounts as views of NAS data rather than duplicate archives, and separate raw media from Resolve project databases and caches. For OBS 30.2+, prefer **Hybrid MP4** over plain fragmented MP4 or the old MKV→MP4 remux workflow: it is crash-resilient during capture and editor-friendly when cleanly finalized. Never delete MKV/MP4 pairs from name matching alone; first compare stream layouts and verify payload identity with FFmpeg stream hashes, write a manifest, then remove only the proven redundant counterpart. See `references/obs-davinci-cross-device-media-workflow.md`.
5. for library cleanup, the post-move duplicate/category checks pass and the manifest path is reported

## Tool Choice Hints

- Use search/discovery helpers when the user does not already have the media file.
- Use delivery helpers when the user already has a file path and wants it sent or attached.
- Use verification before sending large files so you do not hand off the wrong asset.

## Pitfalls

- Sending the wrong file because multiple similar media assets exist
- Assuming a platform accepts every audio/video/image format equally
- Forgetting to verify local file existence before delivery
- Confusing media discovery with media generation
- Permanently deleting NAS media duplicates on the first pass; quarantine with a manifest first, then delete only after explicit approval
- Renaming established library roots like `cartoons` to a nicer name like `animations` without checking downstream path mappings
- Treating exact video height as the only quality signal; cropped 1080p encodes may report heights such as 800/816/1024/1040/1072

## Verification Checklist

- [ ] Source or listing identified
- [ ] File existence or search result verified
- [ ] Correct media type chosen for the destination
- [ ] Delivery or attachment succeeded
- [ ] User-facing result matches the requested asset
