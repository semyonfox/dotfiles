# NAS AI-state staging, normalization, and live-merge workflow

Use when recovered device-dump agent/provider state (`.claude`, `.codex`, `.t3`, `.ollama`, Cursor, Gemini, etc.) should be preserved on the NAS, deduplicated, and assessed for a merge into a live server home.

## 1. Stage safely from device dumps

- Scope source discovery to the archival/device-dump root; never include active `~/.claude`, `~/.codex`, `~/.t3`, or similar live roots as sources.
- Preserve provenance first, for example:
  - `ai-staging/device_dumps/linux-laptop/full-home-current/<provider-root>`
  - `ai-staging/device_dumps/windows_pc/<provider-root>`
- Copy every provider root, SHA-256 verify each regular file and preserve directory/symlink structure, then remove only the verified archival source root.
- Include adjacent explicit provider paths such as `.config/Cursor` and `.config/opencode`; do not move generic `.config` wholesale.
- Treat model stores such as `.ollama` as provider state too. Do not treat a provider-name substring inside unrelated `.claude/projects`, `.t3/worktrees`, or application data as authorization to delete it.

## 2. Normalize before internal dedupe

When the user wants one Linux-equivalent layout, merge Windows provider roots into the Linux-device namespace rather than leaving separate device trees:

1. Choose the Linux full-home provider path as canonical.
2. For each Windows relative path:
   - if absent in Linux, move it into the same Linux-relative path;
   - if the destination has the same SHA-256, discard the duplicate source file;
   - if the same path has different content, preserve it alongside the canonical file with a clear source suffix such as `.windows-pc`; never overwrite.
3. Remove only empty Windows namespace scaffolding after the merge.
4. Write a normalization action audit outside staging.

## 3. Deduplicate storage without breaking state metadata

- Hash all regular files in staging with SHA-256; do not follow symlinks.
- Prefer hardlinks for same-content files only if device, mode, UID and GID match.
- For byte-identical files whose metadata differs, use **Btrfs reflinks**, not hardlinks. Reflinks share data extents while retaining each path's mode, owner, timestamps and xattrs.
- Re-hash every staged file after normalization/deduplication against a fresh pre-dedupe manifest. Do not claim completion merely because the link/reflink command exited successfully.
- Keep audit artifacts outside staging: hashes-before CSV, duplicate groups, hardlink/reflink action lists, normalization actions, post-verification result, errors and a concise report.

## 4. Audit live merge before touching live state

Build a full SHA-256 comparison of each normalized staged provider root against its matching live `~` root. Classify every staged file:

- already at exact live path;
- already present elsewhere under the live provider root;
- missing-path candidate;
- same-path, different-content collision;
- stateful DB/session/log record requiring provider-specific handling;
- cache/vendor/rebuildable material to skip.

Do not interpret “missing” as an automatic live merge. A recovery archive may be intentionally older or an obsolete cache.

## 5. Safe versus unsafe live merges

### Ollama

Content-addressed `models/blobs/sha256-*` plus missing manifests are a clean merge candidate when:

- every candidate was SHA-audited as absent from live `.ollama`;
- every manifest dependency (`config` and `layers` digest) exists in staged or live blobs;
- disk capacity is confirmed and no model is running;
- blobs are copied and SHA-verified to temporary sibling paths, atomically renamed, and manifests are published last.

Do not overwrite `.ollama/history`, identity keys, or config merely because they differ.

### T3 Code

Never filesystem-merge `.t3/userdata/state.sqlite`, WAL/SHM files, event logs, or provider/session records into live state. Even similar schemas can differ (for example, a current live schema may have newer audit tables). Use a clone of the live DB, compare schema and primary-key/event semantics, dedupe/import only through the T3-specific staged merge procedure, and keep raw logs as archival material unless an explicit record-level import is approved.

### Claude, Codex, OpenCode, Serena and IDE agents

- Do not merge plugin Git internals, `node_modules`, language-server bundles, generated caches, or logs into live homes.
- Same-path Git-index/config conflicts are manual review, not an automatic winner choice.
- A small standalone configuration file may be a candidate only after inspecting whether it is path-bound, secret-bearing, or stale.

## Reporting

State separately: what was staged, what was content-deduplicated, what was normalized, what is safe to merge, what is deliberately retained only as archive/reference, and what requires an explicit provider-specific merge.
