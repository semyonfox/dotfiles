# NAS media library audit and dedupe workflow

Session-derived workflow for Semyon's `/mnt/media/arrs` libraries.

## Scope and safety

- Treat media cleanup as potentially destructive. Prefer move/quarantine over delete unless Semyon explicitly asks for permanent removal.
- For NAS/NFS media paths, avoid renaming top-level library roots casually because Jellyfin, Sonarr/Radarr, qBittorrent, and Docker bind mounts may depend on the existing paths.
  - Example: use the existing `/mnt/media/arrs/cartoons` as the animation library rather than renaming it to `animations` just because the user says "animations".
- Always produce a manifest for bulk moves, especially quarantine actions.

## Useful read-only audit commands

Capacity and visible library sizes:

```bash
df -hT /mnt/media
du -h --max-depth=1 /mnt/media/arrs 2>/tmp/arrs-du-errors | sort -h
```

Find duplicate title folders across movie/animation libraries:

```bash
base=/mnt/media/arrs
find "$base/movies" "$base/cartoons" -mindepth 1 -maxdepth 1 -type d -printf '%f\t%p\n' 2>/dev/null \
| awk -F'\t' '{k=tolower($1); gsub(/[^a-z0-9]+/," ",k); gsub(/^ +| +$/,"",k); count[k]++; paths[k]=paths[k]"\n  " $2} END{for(k in count) if(count[k]>1) print count[k]"x "k paths[k]"\n"}' \
| sort -nr
```

Check video file counts by extension:

```bash
find "$base/movies" "$base/cartoons" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' -o -iname '*.iso' \) -printf '%f\n' 2>/dev/null \
| sed 's/.*\.//' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr
```

## Resolution preference for film dedupe

When choosing between duplicate film folders:

1. Prefer the best 1080p-ish copy: video height between about 1000 and 1200 pixels, closest to 1080.
2. If no 1080p-ish copy exists, prefer higher resolution rather than lower.
3. Use width and file size as tie-breakers.
4. If a folder has no video files, treat it as a metadata shell and quarantine it when a real copy exists.

Use `ffprobe` for actual dimensions instead of trusting filenames, because names like `Bluray-1080p` can have active video heights such as 816p or 1040p due to cropping.

Example probe:

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height:format=duration \
  -of json "/path/to/movie.mkv"
```

## Category classification

Prefer local `.nfo` genre metadata when present:

- `<genre>Animation</genre>` means the title belongs in the animation/cartoon library.
- NFO with no Animation genre belongs in movies.
- If no NFO exists, do not over-infer unless the duplicate counterpart has usable NFO or the title is obvious and low-risk.

Verification after moving:

- duplicate normalized title groups across movies/cartoons should be zero unless intentionally duplicated
- movies with Animation genre should be zero
- cartoons with NFO but no Animation genre should be zero

## Quarantine pattern

Use a timestamped quarantine folder under the same filesystem to make moves fast and reversible:

```text
/mnt/media/arrs/_dedupe_quarantine/YYYYMMDD-HHMMSS/
```

Write a JSON manifest containing at least:

```json
{
  "action": "move",
  "reason": "duplicate/category reason",
  "from": "/old/path",
  "to": "/quarantine/or/new/path"
}
```

Report the manifest path and summary counts to Semyon. Do not claim disk space is reclaimed until quarantined files are permanently deleted.

## NAS `df` vs `du` caveat

On Semyon's NFS NAS mount, `df` can show substantially more used space than `du` from `/mnt/media` can account for. Causes may include snapshots, other datasets outside the export, permissions, or export/bind loop oddities. Treat client-side `du` as visible usage only; for true attribution, inspect directly on the NAS host.
