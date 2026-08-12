# OBS Hybrid MP4 and Windows-to-Linux media migration

## OBS recording container: current recommendation

For OBS 30.2+ use **Hybrid MP4** for recordings headed to DaVinci Resolve:

- It writes crash-recoverable fragmented MP4 data while recording.
- On a clean stop OBS finalizes it into a normal, editor-friendly MP4.
- It avoids the old MKV → MP4 remux pair and prevents duplicate storage.
- Prefer it over plain fragmented MP4, which remains fragmented and can seek poorly or have compatibility problems, especially from network storage.

### Config audit

On Linux OBS config is normally under:

```text
~/.config/obs-studio/basic/profiles/<profile>/basic.ini
```

Check both output modes because a profile can retain stale settings:

```ini
[SimpleOutput]
RecFormat2=hybrid_mp4

[AdvOut]
RecFormat2=hybrid_mp4
```

Also inspect Source Record plugin filters in the scene JSON for `rec_format: hybrid_mp4`.

If OBS is not running, back up `basic.ini`, change only stale `RecFormat2=fragmented_mp4` entries, and re-read the file. Do not copy Windows OBS config wholesale over a working Linux profile.

Hybrid MP4 chapter markers can be useful as edit-review markers. Bind the OBS `Add chapter marker` hotkey, but do not depend on them after a crash: chapter metadata is written at finalization.

## Cleaning historical MKV/MP4 remux pairs

Never choose a side by extension/name alone.

1. Pair only matching stems in the same recording tree.
2. Probe duration and stream layout with `ffprobe`.
3. For candidates, hash every encoded stream payload with FFmpeg's streamhash muxer:

```bash
ffmpeg -v error -i INPUT -map 0 -c copy -f streamhash -hash sha256 -
```

4. Delete only one file from pairs whose stream hashes match exactly. For a Resolve-oriented workflow, retain the valid MP4.
5. If an MP4 is unreadable (for example, missing the `moov` atom), retain the valid MKV and remove only the verified broken MP4.
6. Write a JSON manifest of removed paths, sizes, retained counterpart, and reason; verify the survivor exists afterward.

## Migrating legacy Windows media to Linux

Treat Windows footage/assets and DaVinci project data separately.

1. Inventory exact source folders and required Linux capacity first.
2. Copy into namespaced destinations such as `~/Videos/legacy-windows/`, `~/editing/legacy-windows/`, and `~/DaVinci Resolve Media/legacy-windows/` rather than blindly merging into active folders.
3. Copy using `rsync -a --checksum`.
4. Hash source/destination files with SHA-256 before source removal; keep a JSON manifest.
5. Remove only hash-verified Windows sources. Standard Windows user folders may be read-only on an NTFS mount; make only the exact source directory writable when required, then remove the verified files. Leave empty standard Windows folders in place.
6. Do not transplant the Windows DaVinci Resolve application support/cache directory onto Linux. Inspect project-library data separately and retain the active Linux Resolve project database.
