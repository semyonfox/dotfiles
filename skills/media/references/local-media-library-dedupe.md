# Local media library audit and dedupe workflow

Session-derived workflow for cleaning Semyon's NAS media libraries without accidentally deleting good media.

## Scope

Use for `/mnt/media/arrs` style libraries where movies, animation/cartoons, TV, music, books, and downloads are stored as directory-per-title trees.

## Safety rule

Default to **move/quarantine first, delete only after explicit user approval**. For NAS/media libraries, never permanently delete during the initial classification pass.

Recommended quarantine shape:

```text
/mnt/media/arrs/_dedupe_quarantine/<timestamp>/<source-library>/<title>/
```

Write a `manifest.json` with every move:

```json
{
  "action": "move",
  "reason": "duplicate/category correction reason",
  "from": "/old/path",
  "to": "/quarantine/or/new/path"
}
```

## Discovery commands/patterns

- Capacity: `df -hT /mnt/media`
- Top-level usage: `du -h --max-depth=1 /mnt/media/arrs | sort -h`
- Library counts: `find /mnt/media/arrs/movies -mindepth 1 -maxdepth 1 -type d | wc -l`
- Duplicate title keys: normalize folder names to lowercase alphanumeric words, stripping punctuation.
- Media metadata: use `ffprobe` on the largest video file in each title folder.
- Category metadata: parse `.nfo` files for `<genre>Animation</genre>` when available.

## Resolution preference

When duplicate title folders exist, keep the best copy by:

1. Prefer 1080p-ish video: height between 1000 and 1200, closest to 1080.
2. If no 1080p-ish copy exists, prefer the higher resolution.
3. Use width and then file size as tie-breakers.
4. Quarantine lower-scoring duplicates instead of deleting.

Note: common 1080p encodes may report heights like 800/816/1024/1040/1072 because of cropping. Treat the file name and actual dimensions together; don't blindly assume exact 1080 height.

## Category cleanup

- If a movie folder's NFO includes genre `Animation`, move the kept copy to the animation library.
- If an animation/cartoons folder has an NFO and **does not** include `Animation`, move it back to movies.
- If no NFO exists, avoid making aggressive category moves unless it is a duplicate where the other copy's NFO/category makes the answer clear.
- Preserve existing configured library directory names unless the user explicitly asks to rename them. Example: keep `/mnt/media/arrs/cartoons` rather than renaming it to `animations`, because Jellyfin/*arr path mappings may depend on it.

## Verification after moves

Run all checks before reporting success:

```bash
# duplicate title dirs across active movie/animation libraries should be empty
find /mnt/media/arrs/movies /mnt/media/arrs/cartoons -mindepth 1 -maxdepth 1 -type d -printf '%f\t%p\n' \
| awk -F'\t' '{k=tolower($1); gsub(/[^a-z0-9]+/," ",k); gsub(/^ +| +$/,"",k); count[k]++; paths[k]=paths[k]"\n  " $2} END{for(k in count) if(count[k]>1) print count[k]"x "k paths[k]"\n"}'
```

Also verify category mismatches by parsing NFOs:

- movies with `Animation` genre should be 0
- cartoons/animation folders with NFO but no `Animation` genre should be 0

## Common cleanup insight

For Semyon's NAS, duplicate media-library folders may be mostly empty metadata shells, so dedupe may recover little space. Big reclaim candidates are more often completed downloads, e.g. `/mnt/media/arrs/downloads`, but only delete those after checking whether they are still needed for seeding/imports.