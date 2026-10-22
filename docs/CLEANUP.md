# Guarded interactive cleanup

Both shell functions invoke `home/.local/bin/cleanup-caches`. Re-source
`~/.bash_functions` or `~/.zsh_functions` in an already-open shell; its old
in-memory function cannot be replaced by changing files on disk.

```sh
cleanup --help
cleanup --deep --dry-run  # flags combine in either order
cleanup                  # native baseline, uv, and pnpm/npm/pip caches
cleanup --deep           # plus the deep best-effort caches and explicit blockers
```

The Docker/Jenkins/Go build phase uses this server's installed engine:
`~/.hermes/profiles/sean/scripts/hourly-build-cache-clean.sh`. Hosts without it
skip that phase and still run the uv and best-effort phases, serialised by
`~/.cache/cleanup-caches.lock` instead of the engine's `run.lock`. It does not
install a schedule or change the hourly default policy.

The common engine's `--native-only --stdout` interface acquires the existing
`run.lock` and reports this invocation directly, rather than reading a racing
`latest.log`. It uses the separate Jenkins BuildKit daemon's `buildctl prune
--all`, default `docker builder prune -af`, dangling-only `docker image prune -f`,
and native Go **build** cache cleaning. Native in-use protection is not a promise
of reclaim: output retains each command's status and reported logical reclaim.
No volumes or tagged rollback images are pruned. No age floor is introduced.

The frontend also runs native `uv cache prune` for `~/.cache/uv`, plus
`~/.hermes/cache/uv` in deep mode. These exact roots require a valid cache marker,
canonical paths and the existing cleaner lock. UV's own mandatory cache lock
protects running and late-start UV consumers; the installed version was actually
probed offline in both orders. `UV_LOCK_TIMEOUT=1` makes busy caches skip quickly;
`--force` is NEVER used. This restores unused-entry pruning, not full cache clean.
Arbitrary custom/profile uv roots are not swept. Missing/malformed native cache
identities fail closed; dry preview never launches UV.

## Best-effort regenerable caches

These caches only cost a re-download or rebuild if lost, so they are cleared on
a best-effort basis: each is skipped while a matching process runs (`pgrep`), a
`pgrep` failure fails closed, and the whole phase holds the cleaner lock. A tool
that starts mid-clean can still race. That risk is accepted for these paths only.

- baseline: `pnpm store prune`, `~/.cache/pnpm/v*/metadata{,-full}`,
  `npm cache clean --force`, `pip3 cache purge`
- deep: pnpm `dlx`, `~/.npm/_npx`, `~/.bun/install/cache`, `go clean -modcache`,
  `~/.gradle/caches`, Playwright browsers, node-gyp/staticcheck/typescript/jdtls
  and mesa shader caches, `~/.cargo/registry/cache`, the node compile cache, and
  Codex app-server releases other than `current` and the newest previous one

pnpm and npm count as busy only while resolving or installing, not during
long-running `pnpm dev` or `npm start`. The node compile cache has no busy check
because node tolerates it vanishing and some node process is nearly always up.
Removals refuse symlinked or noncanonical paths and anything outside `$HOME`
apart from the node compile cache.

`--dry-run` is a non-mutating plan/inventory, not execution followed by rollback.
Native sizes not available from the read-only inventory are unknown, not zero.
Host path sizes are allocated bytes, may overlap or be hard-linked, and include
protected source/tools for discovery roots. They are never summed or presented
as recoverable bytes. Filesystem available-byte changes include concurrent
activity and are not attributed to cleanup.

## Exit status

- `0`: every selected category ran (or was absent) and nothing is blocked.
- `1`: a native, uv or best-effort category failed or failed closed.
- `2`: invalid or duplicate arguments.
- `3`: no failures, but coverage is incomplete: deep blockers below, or a busy
  cache was skipped. This also applies to previews.
- `75`: another invocation owns the existing run lock. Retry later, not in a loop.

## Unimplemented destructive coverage

These are **not implemented** by reporting their size or a skip. No process
snapshot, readable cwd list, quiet daemon or optional advisory lease certifies
all consumers or prevents a late start. Without authoritative native protection
or enforced consumer admission, the frontend refuses:

- generated outputs under `~/code`, T3 Android outside that root, task workspaces,
  and per-runner HOME caches (installed runtimes/setup-pnpm must not be swept);
- Jenkins exported caches (not the daemon's cache), tagged images without atomic
  rollback/tag-writer coordination, and AI checkpoint retirement without a
  certified checkpoint-only API that preserves canonical history and DB backups.

Existing shared-engine expansion gates remain closed and the hourly job itself is
unchanged; the best-effort phase is interactive-only.

Tests: `bash tests/cleanup.sh` requires both actual Bash and Zsh. It uses isolated
HOME fixtures, a mock engine and mock pnpm/npm/pip/go/pgrep, plus real flock contention, preservation,
argument, failure and incomplete-preview tests. Live engine and syscall evidence
are retained separately with the task report; mock tests alone are not proof of
production cleanup.
