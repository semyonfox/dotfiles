# cleanup

`cleanup` in both shells runs `home/.local/bin/cleanup-caches`. Re-source
`~/.bash_functions` or `~/.zsh_functions` in an already open shell to pick up a
change, the old function stays in memory otherwise.

```sh
cleanup                   # build engine, uv, pnpm, npm and pip caches
cleanup --deep            # plus project build outputs, CI runners, Jenkins exports, old app images and more
cleanup --dry-run         # sizes and what would happen, nothing changes
cleanup --deep --dry-run  # flags combine in either order
```

Output uses the same boxes and `[n/total]` steps as `update`, one line per cache
with its size before and after. Tool output is only shown when a tool fails.

## Steps

1. Build caches. On the server this runs the Hermes hourly cleaner
   (`~/.hermes/profiles/sean/scripts/hourly-build-cache-clean.sh --native-only
   --stdout`), which prunes the Jenkins BuildKit daemon, the default Docker
   builder, dangling images only, and the Go build cache through the tools' own
   prune commands. Its log is summarised to one line per category and shown in
   full only for the categories that failed. Hosts without the engine skip this
   step.
2. uv cache. `uv cache prune` on `~/.cache/uv` (deep adds `~/.hermes/cache/uv`),
   offline, with `UV_LOCK_TIMEOUT=1` and never `--force`, so uv's own cache lock
   protects a running uv. A root without a valid `CACHEDIR.TAG`, or behind a
   symlink, is refused.
3. Project build outputs (`--deep`). Scans `~/code`, `~/t3code-mobile-work`,
   `~/.t3/worktrees`, `~/.t3/scratch` and `~/.hermes/kanban/boards`. Inside a git
   repo it removes `node_modules`, `build`, `dist`, `target`, `.next`, `.venv`,
   `__pycache__` and similar, but only when git ignores the dir and tracks
   nothing in it, and never a `build`/`dist`/`out` holding an `.apk`, `.aab` or
   `.ipa`. Outside git only pure caches go: a `node_modules` next to a
   `package.json`, a `.venv` with a `pyvenv.cfg`, `__pycache__` and the like,
   never a `build` or `dist`. A project is skipped while any of your processes
   runs in it, from it, or names it in its arguments, and when its HEAD reflog,
   root dir or an output dir changed in the last day. The git index is ignored
   for that, every `git status` rewrites it. Paths inside an uninitialised
   submodule are kept.
4. CI runner caches (`--deep`). For each runner under `~/actions-runners`, its
   pnpm store, `home/.cache`, npm cache and repo checkouts under `_work`, all
   rebuilt by the next job. Skipped while that runner's `Runner.Worker` (a job)
   runs. The runner install, `externals`, `_work/_tool` and `_work/_actions` stay.
5. Package caches. `pnpm store prune`, `~/.cache/pnpm/v*/metadata{,-full}`,
   `npm cache clean --force`, `pip3 cache purge`. This runs after steps 3 and 4
   so the store prune drops packages only their `node_modules` linked to.
6. Deep caches (`--deep`). pnpm dlx, `~/.npm/_npx`, bun, `go clean -modcache`,
   `~/.gradle/caches`, Playwright browsers, node-gyp, staticcheck, TypeScript,
   jdtls and Mesa shader caches, `~/.cargo/registry/cache`, the node compile
   cache, and Codex app-server releases other than `current` and the newest other
   one.
7. Jenkins cache exports (`--deep`). The BuildKit exports in the agent's
   `/home/jenkins/cache/buildkit`, removed with `docker exec` only while the
   agent runs nothing but its own JVM. Every pipeline does `mkdir -p` on its
   cache dir and rotates it through `-new`, so a missing one is a cold build.
8. Old app images (`--deep`). The Hermes policy
   (`hourly-tagged-image-policy.py --dry-run`) picks unused, single-tagged commit
   images beyond the two newest unused per app. Each is rechecked for the same
   tags just before `docker image rm <id>`, never forced, so Docker itself
   refuses while any container uses it.

Steps 2 onwards hold the hourly cleaner's `run.lock` where it exists, otherwise
`~/.cache/cleanup-caches.lock`, so two cleanups never overlap. If the engine
already found that lock busy the remaining steps are skipped and the exit is 75.
Each cache is skipped while a matching process runs (`pgrep -f`), in a dry run
too, so the preview shows what a live run would skip. A failing `pgrep` refuses
the item instead of guessing. pnpm and npm only count as busy while installing
(flags before the subcommand are fine), not under `pnpm dev` or `npm start`.
Symlinked or noncanonical paths and anything outside `$HOME` (apart from the
node compile cache) are refused. A Codex layout the script cannot read refuses
the Codex items only, the unrelated caches still run and the exit is 1. A tool
or job starting mid-clean can still race, the worst case is a cold rebuild, a
re-download or a CI job to re-run, never lost work.

Sizes are `du` allocated bytes. `Freed` is the change in free space on `/` over
the whole run, as in the old shell box. Per-item figures can't be summed:
Docker's reclaimed totals count shared layers and pnpm `node_modules` are
hardlinks into the store. Other disk activity during the run shows up in it too.

## Left alone

`--deep` ends by naming what it never touches because it is data, not cache: AI
history and checkpoints (T3, Codex, Claude, opencode, Hermes), T3 update
backups, Docker volumes and rollback image tags. Clearing any of those is a
decision, not a cleanup.

## Exit status

- `0`: everything selected ran or was absent.
- `1`: something failed or was refused.
- `2`: bad arguments.
- `3`: nothing failed, but something in use was skipped.
- `75`: another cleanup holds the lock, try again later.

Tests: `bash tests/cleanup.sh` needs real bash and zsh. It runs both wrappers
against an isolated HOME with a mock engine speaking the real log grammar, mock
pnpm, npm, pip, go, uv, pgrep and docker, real git repos and real flock
contention. The mock docker is always first on `PATH`, so no test reaches the
host's Docker. `CLEANUP_HOST_TMP` exists so the suite's node compile cache
fallback stays inside the fixture instead of `/tmp`.
