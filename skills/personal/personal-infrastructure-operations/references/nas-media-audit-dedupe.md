# NAS media audit and dedupe pattern

Session-derived workflow for auditing `/mnt/media` and cleaning Semyon's media libraries safely.

## Read-only NAS usage audit

Useful probes:

```bash
df -hT /mnt/media
df -ih /mnt/media
findmnt -T /mnt/media -o TARGET,SOURCE,FSTYPE,OPTIONS
du -h --max-depth=1 /mnt/media 2>/tmp/nas-du-errors | sort -h
```

Interpretation rule:

- `df` reports total filesystem/export usage.
- Client-side `du` only accounts for what the NFS client can traverse.
- If `df` is much larger than `du`, likely causes include NAS snapshots, hidden datasets, permission-denied directories, or export/bind loops. Do not claim space is cleanly attributable from the client alone.
- Loop warnings such as repeated inode/root-like dirs on NFS should be treated as an export/client visibility issue until checked directly on the NAS.

## Media library inventory

Useful roots from this session:

```text
/mnt/media/arrs/movies
/mnt/media/arrs/cartoons
/mnt/media/arrs/tvshows
/mnt/media/arrs/music
/mnt/media/arrs/books
/mnt/media/arrs/downloads
```

Use `find`/`du` to count folders and rank heavy directories. For title duplicates across libraries, normalize names by lowercasing and replacing non-alphanumerics with spaces.

## Dedupe policy that worked

For duplicate film/title folders:

1. Identify main video file by largest video file in the folder.
2. Use `ffprobe` to read video height/width.
3. Prefer 1080p-ish copies first: height between 1000 and 1200, closest to 1080.
4. If no 1080p-ish copy exists, prefer higher height; then width; then file size.
5. Use `.nfo` `<genre>Animation</genre>` to decide whether the kept copy belongs in `cartoons` or `movies`.
6. Quarantine lower-preference copies under a dated directory with a JSON manifest. Do not delete on the first pass.
7. Verify active duplicate groups are gone and category mismatches are zero.
8. Delete quarantine only after Semyon explicitly confirms.

## Category sorting notes

- The existing `cartoons` path should be treated as the animation library. Do not rename it to `animations` without explicit approval because Jellyfin/Radarr/Sonarr mappings may depend on the root path.
- NFO genre checks are safer than title guesses for distinguishing live-action remakes from animated originals.
- Examples of live-action/non-animation titles that belonged in movies during this session: `Alien - Covenant`, `Avatar (2009)`, `Aladdin (2019)`, `The Fly (1986)`, `Popeye (1980)`, `Shrek the Musical`, `How to Train Your Dragon (2025)`.

## Cleanup target lesson

Duplicate category cleanup may improve library hygiene without reclaiming much space if duplicate folders are empty metadata shells. Downloads can be a much larger reclaim target, but should be treated separately and checked for seeding/import state before deletion.
