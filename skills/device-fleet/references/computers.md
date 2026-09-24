# Semyon's Device Fleet

Last refreshed: 2026-08-12 from `server` using non-sudo local and SSH probes, plus prior documented maintenance work.

This file is the canonical inventory for the `device-fleet` skill. Do not store passwords, private key material, Tailscale auth keys, recovery codes, or other secrets here. Sudo passwords are provided by the user per task when needed and are never persisted.

## Operating Model

- Verified 2026-09-18: experimental T3 and both proxies retired. Normal T3
  active on 3773 with direct providers; ports 3774/8317/8318 closed. Five new
  messages merged into original threads and native logs copied to host homes.
  Experimental containers, image tags, volumes and full staging backups deleted
  after verification. Small merge record `~/.local/share/t3-preview-merge-20260918`.
  No-expiry native-session archive remains enabled. See `references/t3-code.md`.

- Verified 2026-09-11 14:02 IST: laptop direct Tailscale SSH at `semyon@100.127.128.15` works (CachyOS kernel `7.2.3-1-cachyos`). Its Helium/Hyprland desktop can be controlled with `hyprctl`, `wtype` and `grim` over `wayland-1`. Screen scale is 1.25; input coordinates are logical, screenshots physical. Discover the current Hyprland instance rather than persisting its session identifier. This `wtype` build accepts plain text only; use Hyprland's `sendshortcut` dispatcher for non-text keys.
- Verified 2026-09-11: Fox Focus runs on `server` as Docker Compose project `fox-focus`, with `app` and `tunnel` containers, host loopback port 8789 and named SQLite volume `fox-focus_focus-data`. Dedicated Cloudflare route `focus.semyon.ie` targets `http://app:8789`. No systemd service was added. Deployment instructions live in `/home/semyon/code/owned/labs/fox-focus/docs/deployment.md`.
- Verified 2026-09-11: Jenkins job `fox-focus` on `docker-agent` follows `semyonfox/fox-focus` `*/main` and its checked-in `Jenkinsfile`. GitHub push webhook `677639866` and an `H/10` SCM poll trigger start deployments; Jenkins itself builds and tests the immutable commit-tagged image, so GitHub Actions and GHCR are not in the production path. The persistent job definition is `server-stacks/jenkins/fox-focus/job-config.xml`, seeded by `jenkins/init.groovy.d/seed-fox-focus.groovy`; the operator-owned deployment Compose file is `jenkins/fox-focus/compose.yaml`. Build #7 successfully deployed `8fa3ae23345c0eef29411a52454d1e48b98d31d7`, retaining `fox-focus_focus-data`, the read-only Hermes mount, all three read-only OAuth file mounts, and the separately managed tunnel. Google is configured; Microsoft is intentionally unconfigured through a non-secret placeholder. Public health passed, authenticated workspace and integration probes returned 200, and anonymous workspace routes returned 401.

- Control node: `server` in `/home/semyon`.
- SSH user: `semyon` unless a device section says otherwise.
- Primary key path in SSH config: `~/.ssh/id_ed25519`; do not read the private key.
- LAN subnet observed from `server`: `10.0.0.0/24`.
- Default gateway/router: `10.0.0.1`, ping reachable on 2026-07-03. Admin UI and credentials are unknown. Treat router changes as high risk and ask before touching them.
- Tailnet suffix observed from Tailscale status: `taild7128c.ts.net`.
- MagicDNS caveat: `getent hosts *.taild7128c.ts.net` returned no records from `server` on 2026-07-03. Use raw Tailscale IPs when MagicDNS does not resolve.
- Access preference: existing SSH alias, then LAN IP, then Tailscale IP/DNS, then documented proxy path.
- T3 Code caveat: the verified normal setup is on `server` as an installed global `t3` CLI managed by an enabled user systemd service. Do not assume `npx t3@nightly serve`; see `references/t3-code.md`.

## Access Matrix

| Device                          | Role                                                          | SSH / Access                                                                             | LAN         | Tailscale                                                             | Status notes                                                                                                |
| ------------------------------- | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------- | ----------- | --------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `server`                        | Control node, agent host, T3 Code headless                    | `ssh server`                                                                             | `10.0.0.5`  | `100.118.61.122`, `server.taild7128c.ts.net`                          | LAN and Tailscale local; T3 systemd service active                                                          |
| `nas`                           | NAS/storage, Docker services, proxy jump for laptop LAN alias | `ssh nas`                                                                                | `10.0.0.6`  | `100.65.148.17`, `nas.taild7128c.ts.net`                              | LAN SSH works; Tailscale ping timed out                                                                     |
| `pc`                            | Dual-boot desktop PC, GUI/RustDesk, code work on LAN          | CachyOS: `ssh pc` / `ssh cachy-pc`; Windows: `ssh winpc` / `ssh windows-pc`              | `10.0.0.15` | Windows tailnet entry `100.77.148.51`; Linux SSH env has no Tailscale | Separate host-key identities prevent collisions when the booted OS changes                                    |
| `laptop`                        | ThinkPad/CachyOS mobile machine, remote T3/Ollama             | `ssh laptop` via LAN/NAS proxy; direct Tailscale `ssh semyon@100.127.128.15` when online | `10.0.0.17` | `100.127.128.15`, `semyons-laptop.taild7128c.ts.net`                  | LAN SSH worked on 2026-07-04; direct Tailscale SSH timed out and Tailscale listed the node recently offline |
| Android phone: Samsung SM-A546B | Low-priority mobile device                                    | No SSH documented                                                                        | Unknown     | `100.84.250.104`, `samsung-sm-a546b.taild7128c.ts.net`                | Offline/expired Tailscale entry                                                                             |
| Android phone: Xiaomi 11T Pro   | Low-priority mobile device                                    | No SSH documented                                                                        | Unknown     | `100.104.248.28`, `xiaomi-11t.taild7128c.ts.net`                      | Offline Tailscale entry                                                                                     |

## SSH Config Snapshot

Source: `/home/semyon/.ssh/config`, read 2026-08-26.

```sshconfig
Host server 10.0.0.5
    HostName 10.0.0.5
    User semyon
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host nas 10.0.0.6
    HostName 10.0.0.6
    User semyon
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# The PC dual-boots. Keep each OS on a distinct SSH host-key identity.
Host pc cachy-pc semyons-pc
    HostName 10.0.0.15
    User semyon
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    HostKeyAlias semyons-pc-cachy

Host winpc windows-pc
    HostName 10.0.0.15
    User foxsc
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    HostKeyAlias semyons-pc-windows

Host laptop cachy-laptop 10.0.0.17
    HostName 10.0.0.17
    User semyon
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ProxyCommand ssh nas nc %h %p
```

The laptop alias depends on `nas` and the laptop LAN IP. On 2026-07-04, `ssh laptop` reached `10.0.0.17`; direct Tailscale IP SSH timed out.

## Devices

### `server`

- Role: control node/orchestrator, local machine for this Codex session, and verified T3 Code headless host.
- Hostname: `server`.
- Hardware: Dell XPS 15 9570, laptop chassis (verified 2026-08-12 via `hostnamectl`). Earlier Latitude 5480/network-adapter notes are stale and must not be used for hardware decisions.
- GPU verified 2026-07-16: Nvidia GeForce GTX 1050 Ti Max-Q, compute capability 6.1, 4,096 MiB VRAM. It cannot host the unquantised 19 GB Qwen3.5-9B benchmark configuration.
- OS: Ubuntu 24.04.4 LTS, kernel `6.8.0-137-generic` (verified 2026-08-12).
- Access: `ssh server`, `ssh 10.0.0.5`, or local shell.
- Network: LAN `10.0.0.5/24`; Tailscale `100.118.61.122`; Tailscale DNS `server.taild7128c.ts.net`.
- Tailscale notes: self node advertises `10.0.0.0/24` as a primary route; verify route status before relying on it from another machine.
- Verified 2026-09-24: private portfolio review is served at `https://server.taild7128c.ts.net:8446/` through Tailscale Serve, tailnet-only (not Funnel), from immutable static snapshot `/home/semyon/.local/share/portfolio-preview-20260924-XbMbbxHS` built from commit `b12179c`. Home, projects, CV and games returned HTTP 200 from `semyons-laptop` over Tailscale. It is separate from the public portfolio deployment and existing Serve ports. `tailscale serve --https=8446 off` removes this endpoint when the review is finished.
- Verified 2026-09-24: portfolio PR #67 merged as `9bef484`. Jenkins job #114 built both images but failed before deployment because Docker's default network address pools were exhausted during candidate smoke. A candidate test using the unused `172.16.250.0/29` bridge subnet passed. The existing production frontend and chat API were then recreated from the Jenkins-built `portfolio-portfolio:9bef484` and `portfolio-chat-api:9bef484` images; the `chat-data` volume and tunnel were retained. Local and public home/API smoke passed, and public home, projects, CV and games served the new content. Previous images are tagged `portfolio-portfolio:rollback-20260924-9bef484` and `portfolio-chat-api:rollback-20260924-9bef484`. The live Jenkins job still uses automatic candidate-network allocation and needs a durable fix before the next automatic deployment.
- FlyChess remote dashboard verified 2026-09-21: `https://server.taild7128c.ts.net:8791/` is Tailscale Serve, tailnet-only (not Funnel), and was tested from `semyons-laptop`. It proxies through the loopback-only `fly-chess-tailscale-proxy` tmux session at `127.0.0.1:8792` to the existing `10.0.0.5:8791` dashboard; restart that session after a server reboot.
- Between Moves chess analyser verified 2026-09-23: `https://server.taild7128c.ts.net:8445/` is a tailnet-only Tailscale Serve route to `127.0.0.1:3001`. Project: `/home/semyon/code/owned/labs/chess-analyser`; `APP_ORIGIN` matches that HTTPS URL. Enabled user services `chess-analyser-web.service` and `chess-analyser-worker.service` restart automatically. User lingering is enabled. Unit sources live in the project's `deploy/systemd/`; installed copies use `~/.local/bin/node` and read the project's `.env.local` without copying it. Web currently uses `NEXT_DIST_DIR=.next-release-6` (with `.next-release-4` kept for rollback); future builds must use a different directory while this one is serving traffic, then update the unit after verification. Database container `chess-analyser-db-1` is healthy with restart policy `unless-stopped`. Tailscale HTTPS `/sign-in` and `/icon.svg` returned 200 after deployment. Local MagicDNS resolution still requires mapping the hostname to `100.118.61.122` for checks. Existing Serve ports `8444` and `8791` are separate services.
- Agent tooling verified 2026-08-12: `tmux 3.4`, `codex-cli 0.147.0`, Node `v24.16.0`, `npx 12.0.2`, Docker `29.7.2`.
- Native AI CLIs verified 2026-07-25: Claude Code `2.1.220` is installed by Anthropic's native installer at `~/.local/share/claude/versions/2.1.220`, with `~/.local/bin/claude` as the managed launcher, auto-updates enabled, the `latest` channel selected, and `claude doctor` reporting no installation issues. OpenCode `1.18.5` is installed by its official release installer at `~/.opencode/bin/opencode`, with a convenience symlink at `~/.local/bin/opencode`. The conflicting global npm packages `@anthropic-ai/claude-code` and `opencode-ai` were removed from the active nvm prefix.
- Claude history consolidation verified 2026-07-26: all 238 discoverable non-backup local `~/.claude/projects` archive roots were inventoried and merged into the live server `~/.claude/projects` tree with Windows structural paths normalized to `/home/semyon`. The canonical result contains 462 root sessions, 735 subagent sessions, and 131,687 events; 5,347 duplicate events were removed. Validation found zero duplicate root identities, duplicate subagent identities, duplicate event UUIDs, malformed JSONL records, legacy structural paths, or unlisted local archive roots. The pre-merge tree is recoverable at `~/.claude-history-backups/20260725-235913/projects`; detailed reports are in `~/claude-history-merge-applied-20260725` and the exhaustive second-pass audit is in `~/claude-history-merge-second-dryrun-20260725`.
- T3 Code verified 2026-07-03: `/home/semyon/.local/bin/t3` is installed and `t3-code-headless.service` is enabled and active under user systemd. It starts through `/home/semyon/bin/t3-headless-preflight` and `/home/semyon/bin/t3-headless-run`, listens on `0.0.0.0:3773`, uses base dir `/home/semyon/.t3-code`, and is protected by `/home/semyon/.t3-code/t3-headless.lock`. User lingering is enabled. See `references/t3-code.md`.
- CLIProxyAPI/claudex verified 2026-07-16: user-local CLIProxyAPI `7.2.78` is enabled and active on `127.0.0.1:8317` with separate Codex and Claude OAuth auth files, private client-key/config permissions, and `/home/semyon/.local/bin/claudex`. Direct Sol, Terra, Luna, Anthropic-compatible, Claude print-mode, and stream-JSON tests passed. T3 has a separate `claudex` Claude-driver instance with friendly Sol/Terra/Luna presentation and Low/Medium/High/Extra High effort controls; the wrapper maps selections to `gpt-5.6-*`, aligns explicit/environment effort, and pins subagents. T3's saved exposure mode is `local-only`, but the managed headless unit still regenerates/listens on `0.0.0.0:3773`; treat loopback-only T3 binding as unresolved.
- Agent instruction scan verified 2026-07-06: active `~/.claude/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.claude/fable-codex-orchestration.md` are symlinked into `~/dotfiles/claude/.claude/`; `~/.codex/AGENTS.md` exists separately and contains the personal device-fleet default. The server `~/dotfiles` directory was not a Git repository during this scan.
- Dotfiles audit verified 2026-07-06: `~/dotfiles` is a Git clone of `git@github.com:semyonfox/dotfiles.git` on `master`; GitHub SSH auth works from the server. Public consolidation commit `6e83e0e` is pushed to `origin/master` and introduces the profile model: `server` = `home claude server`, `pc` = `home claude hyprland waybar swaync rofi pc`, `laptop` = `home claude hyprland waybar swaync rofi laptop`, and `nas/minimal` = `home claude`. The previous non-Git server-only directory was moved to `~/dotfiles_pre_git_20260706-191336`, with a focused Claude backup at `~/dotfiles_server_claude_20260706-191336`. Claude guidance is now tracked under `claude/.claude/AGENTS.md`, `CLAUDE.md`, and `fable-codex-orchestration.md`; Codex defaults remain separate. Live shell/git configs such as `~/.bashrc`, `~/.zshrc`, `~/.zshenv`, `~/.bash_functions`, and `~/.gitconfig` remain regular files until the profile is explicitly stowed.
- Agent source update verified 2026-07-06: public dotfiles commit `fd9cb98` is pushed to `origin/master` and adds tracked Claude subagent markdown, the public university metadata standard reference, and an optional `codex` stow package for `~/.codex/AGENTS.md` plus non-system Codex skills. Private `device-fleet` references remain local-only and are not tracked.
- Dotfiles cleanup verified 2026-07-07: public commit `4040e89` is pushed to `origin/master` and fixes Hyprland `source =` lines by moving comments off the source directives. Server `~/dotfiles` is clean at `4040e89`, and the server profile `stow --no-folding home claude server` is deployed. Pre-stow real-file conflicts were preserved at `~/dotfiles_stow_conflicts_server_20260707-110511`. `t3-code-headless.service` remained active after stowing.
- Related T3 units: `t3-code-headless-update.path` exists but is disabled/inactive; `t3-code-headless-restart.service` is a static oneshot; `t3code-hyperion.service` exists but is disabled/inactive.
- User services observed: `t3-code-headless.service`, `agent-runner.service`, `hermes-dashboard.service`, `hermes-gateway.service`.
- Marker++ comparison lab verified 2026-07-22: enabled user service
  `marker-comparison-dashboard.service` listens on `0.0.0.0:4173`. LAN URL is
  `http://10.0.0.5:4173/`; Tailscale URL is
  `http://100.118.61.122:4173/`. Its custom handler serves the dashboard and an
  explicit `/evidence/` allowlist without exposing the repository or raw PDFs.
- Seol verified 2026-07-23: Docker containers `seol` and `seol-tunnel` serve
  <https://seol.semyon.ie>. The application runs image `seol:3bff959`, persists
  metadata/content in named volume `seol-data`, restarts unless stopped, and
  binds only `127.0.0.1:8788`. Publishing and management require one configured
  bearer token; `/p/{id}/` page links are public. The stopped
  `pagedrop-pre-seol-v2-20260723` container and untouched `pagedrop-data` volume
  are retained temporarily for rollback.
- Erugo publishing verified 2026-08-04: Docker container `erugo` runs
  `wardy784/erugo:latest` on local port `3003`, with public shares served from
  <https://fileshare.semyon.ie>. The existing one-file TUS publisher is
  `/home/semyon/t3build/publish-erugo.sh`; it sources credentials from the
  private fileshare stack environment and creates shares that expire after
  seven days. Its upload metadata is APK-specific, although other file types
  such as ZIP archives upload and download successfully. Erugo's normal share
  download returns an archive, and its individual-file route still identifies
  APK bytes as `application/zip`. For Android delivery, the bind-mounted
  `/network-rush.apk.php` endpoint serves
  `storage/app/public/apk/network-rush-prototype.apk` with the Android package
  MIME type, an `.apk` content-disposition filename, and `nosniff`.
- Jenkins/Seol CI/CD verified 2026-07-23: Jenkins `2.555.3` runs in Docker as
  `jenkins-jenkins-1` with `jenkins-tunnel-1` at
  <https://jenkins.semyon.ie>. The `seol` job follows repository branch `main`;
  it repeats Go vet, race-enabled tests, and formatting checks, builds a
  commit-tagged image, smoke-tests an unprivileged disposable candidate,
  deploys with the existing `seol-data` volume and preserved runtime
  configuration, retains `seol-previous` for rollback, and checks the public
  health endpoint and homepage. GitHub webhook `655956859` on
  `semyonfox/seol` sends push events to the Jenkins GitHub endpoint; its initial
  ping returned HTTP 200. Jenkins build 3 completed successfully. GitHub
  Actions remains the repository-wide CI for pushes and pull requests; Jenkins
  is production CD from `main`.
- Jenkins/Swim recovery verified 2026-08-10: Jenkins was upgraded from
  `2.568.1` to `2.568.2` through a safe restart, which intentionally terminated
  the in-flight Swim production and dev client test shells. Clean reruns
  `swim #300` and `swim-dev #127` both passed the DB smoke suite and all 99
  client test files / 631 tests before building and deploying successfully.
- Swim Jenkins jobs verified 2026-08-02: the live controller has separate
  `swim` and `swim-dev` pipeline jobs. `swim` checks out `main`, uses the
  production stack environment, runs tracked SQL migrations, and deploys the
  production API/client. `swim-dev` checks out `dev`, uses `stack-dev.env`,
  runs the same migration runner against the dev database, and deploys
  `swim-api:dev-latest` plus `swim-client:dev-latest`. Dev build 104 applied
  `20260802_180000_align_form_contracts.sql`, recreated both dev containers,
  and finished successfully; the dev API health endpoint reported its database
  connected.
- SWIM database split verified 2026-09-22: production uses `pg-db`/`uisce`
  with volume `uisce_pg_db_data`; deployed `https://swim-dev.semyon.ie` uses
  `pg-db-dev`/`swim_dev` with volume `uisce_pg_db_dev_data`; the private E2E
  preview uses `swim-e2e-postgres`/`swim_e2e` with its own volume. These are
  separate containers and databases. The dev API/client bind to loopback ports
  4010/4011. The dev API now has wellness and video enabled, with private
  video storage at `uisce/data/dev-video-feedback` mounted only into `api-dev`.
  AI remains unavailable until an OpenRouter key and budget limits are set;
  the dev model override is `openai/gpt-6-luna`.
- Cross-device AI history canonicalization verified 2026-07-26: the server live
  roots are canonical for Claude, Codex, Gemini, T3, OpenCode, and Copilot.
  Schema-aware merges recovered 11 snapshot-only Claude sessions, 18 T3 turns
  (15 from PC and 3 from NAS), the historical OpenCode DB rows, and 23,852
  legacy Codex operational log rows. Final live counts include 483 Claude root
  sessions plus 737 subagents, 53 Gemini sessions, 6,178 T3 projection turns,
  and 21 OpenCode sessions / 615 messages / 2,641 parts. Final dry runs report
  zero missing provider records, zero Claude duplicate events or legacy
  structural paths, and valid SQLite integrity/foreign-key checks. One named
  rollback per provider was initially retained under the corresponding
  `~/.{provider}-history-backups` or `~/.t3-migration-backups` root.
- Canonical history follow-up verified 2026-08-01: a second schema-aware audit
  recovered five missing Claude events and 309,938 historical Codex operational
  log rows. Two remaining Codex Windows-home `cwd` values were normalized to
  `/home/semyon`; T3, Gemini, OpenCode, and the older Codex JSONL rollback were
  already logically covered, so no duplicate records were inserted. Unique
  OpenCode agents, commands, skill, plugin, and configuration were merged into
  `~/.config/opencode`, with current live values and the newer live auth taking
  precedence. After subset, integrity, foreign-key, path, and open-file checks,
  the seven provider/config rollback roots were permanently removed; no
  per-provider history rollback root remains in the server home directory.
  The completed one-off canonicalization/reconciliation reports, migration
  tools, and their matching Trash entries were removed at the same time.
- Copilot application-store audit verified 2026-07-26: canonical
  `~/.copilot/session-store.db` passes integrity and contains two session stubs
  with zero turns; its historical NAS DB was byte-identical and PC had no
  Copilot DB. Two NAS copies of one VS Code `chatSessions` record were exact,
  empty duplicates (`0` requests) and were removed. Forty-one historical
  JetBrains workspace files contain only Copilot tool-window/plugin migration
  references; no conversation store was found in NAS dumps/backups or the PC's
  mounted Windows AppData. IDE settings and plugin installations were retained.
- AI staging cleanup verified 2026-07-26: exact, ledgered server cleanup removed
  about 35.66 GB of superseded merge inputs, projections, nested provider
  roots, and old rollbacks. Live provider/config roots and analysis source
  repositories were retained. The usage dashboard was refreshed from
  `bunx ccusage --json` and replaced in place at
  <https://seol.semyon.ie/p/bTGtQ1oW3LIAr5AQZUu5aQ/>.
- Server home cache cleanup verified 2026-08-01: removed 23.9 GiB of
  regenerable XDG, Gradle, npm/npx, NVM, Bun, Cargo registry, pnpm-store,
  Claude, Codex, and Hermes cache data, plus the broken
  `~/ai-yoink-run-current` symlink. `~/.t3` and
  `~/.hermes/state-snapshots` were explicitly preserved, and the T3 service
  remained active. A separate `~/.git` audit found an unborn `master` repo with
  no commits, remotes, refs, reflogs, index, or tracked files. Follow-up traced
  it to failed T3 checkpoint captures for the oversized `/home/semyon`
  workspace: all 33 recorded checkpoint refs were already marked missing, no
  commit refs existed, and repeated 30-second timeouts had grown unreachable
  objects to 7.39 GB. The stray home-level `.git` was permanently removed;
  `~/dotfiles/.git` remained a separate valid repository and T3 stayed active.
- Server home backup cleanup verified 2026-08-01: permanently removed the
  user-owned dated AWS, Cloudflared, Docker, Wrangler, GitHub, rclone,
  configstore, dotfiles, Hermes, Claude, Codex, Swim, database-dump, and general
  backup/rollback targets inventoried under the home directory, totaling about
  6.85 GiB. `~/.t3`, `~/.local/share/t3-cliproxy-backups`, and
  `~/.hermes/state-snapshots` were explicitly preserved at that stage. The
  final 20 KiB root-owned LAN-DNS subtree was subsequently removed.
- Server one-off backup migration verified 2026-08-02: checksum-matched Hermes
  state/curator snapshots, T3 deploy artifacts, project recovery bundles,
  dormant-service archives, Pi-hole recovery data, Uisce dumps, and stale
  `.bak` files were consolidated into the single private NAS archive
  `/mnt/media/users/semyon/backups/server/archive/retired-home-backups-20260802`
  (4.6 GiB) and removed from the server home and NAS `current` mirror. The
  cliproxy artifact tree was the only path not already present in `current`; it
  was copied once, checksum-verified, then removed locally. Hermes curator and
  pre-update local backup creation are disabled. Live app-native backup targets
  remain for Pi-hole (~1.8 MiB), Erugo (~3.5 MiB), and the four empty Servarr
  bind-mount directories. The weekly `server-nas-backup.timer` remains enabled;
  a repaired run completed successfully with a 45 GiB current mirror, 27 MiB
  manifest, and `COMPLETE` marker while T3 stayed active. NAS Btrfs daily,
  weekly, and monthly snapshots were verified current on the same date.
- Protection audit 2026-08-02: the consolidated archive was created after the
  04:00 daily users snapshot, so its first complete scheduled Btrfs snapshot is
  2026-08-03 at 04:00 unless one is triggered earlier. The 2026-08-02 snapshot
  retains several predecessor trees but not the full archive, notably excluding
  the roughly 2.2 GiB dormant-services tree. Existing Backblaze B2 jobs do not
  include `/mnt/media/users/semyon/backups/server`.
- Backblaze Restic audit 2026-08-02: Immich was current (latest snapshot
  2026-08-02) and Polina's copy timer succeeded. `semyon-laptop-b2-copy` and
  `semyon-pc-b2-copy` had failed since 2026-07-31 because their copy script
  omits a Restic source repository option (`--from-repo` or equivalent). Their
  B2 repositories remained readable but stale (laptop latest 2026-07-29; PC
  latest 2026-07-30).
- Lidarr decommission verified 2026-08-24: after the 2026-06-28 rogue mass-add of
  603 monitored artists caused ~200 GB of unwanted auto-downloads (root-caused in
  failed T3 thread `11727c4e`), all 603 non-original artists were deleted from
  Lidarr via API with `deleteFiles=false`. Exactly the 10 pre-June-2025 adds
  remain monitored: Eminem, Marshmello, Post Malone, Taylor Swift, Morgan Wallen,
  Shaboozey, Katy Perry, Shania Twain, KNEECAP, NF (Lidarr IDs 1–10). Queue is
  empty; Lidarr→qBittorrent client stays disabled; `qbittorrent` container remains
  intentionally frozen via `docker pause` (resume with `docker unpause`). All disk
  content was preserved: `/mnt/media/arrs/music/albums` keeps ~925 artist folders /
  265 GB including original beets rips. Pre-change rollback snapshot:
  `~/lidarr-decommission-backup-20260824-2245` (`lidarr.db`, 426 MB, plus
  `artists-manifest.json` listing every removed artist's MBID and path).
- Traein (Irish Rail dashboard) verified 2026-09-12: runs on `server` as Compose project `irish-rail-nabber` from `/home/semyon/server-stacks/irish-rail/stack.yaml` with private env file `stack.env` (mode 600; containers `irish_rail_db/api/daemon/dashboard/cloudflared`, public at <https://traein.semyon.ie>). The API is internal to the Compose network with no host-published port; check it with `docker exec irish_rail_api curl -fsS http://127.0.0.1:8000/health`. Rate-limit defaults are free 25,000 / coffee 100,000 req/day. Daily counters live in Postgres table `api_daily_usage`; a stuck IP can be reset by deleting its `for_date = CURRENT_DATE` row.
- Traein Clerk production verified 2026-09-12: production email/password auth is live; Google OAuth is disabled in production because no custom Google credentials were provisioned. The DNS-only Clerk frontend, account-portal, and three email CNAMEs are verified in Cloudflare, and exact-host TLS is issued for `clerk.traein.semyon.ie` and `accounts.traein.semyon.ie`. Live keys are in server `stack.env` and laptop `~/.config/traein/clerk-prod.env`, both mode 600. API/dashboard/daemon run the Clerk images; previous images have tag `pre-clerk-20260912`. Migration 009 added `users.clerk_user_id` and made `password_hash` nullable while deliberately retaining `refresh_tokens` for rollback. Private pre-cutover backups are under `/home/semyon/server-stacks/irish-rail/backups/`.
- Traein auth and chat follow-up verified 2026-09-12: API/dashboard candidates `postauthfix-20260912` are live, with rollback aliases `pre-postauthfix-20260912`. Clerk owns dynamic auth headings, including verification-code instructions; identity changes clear local user state and the GraphQL cache; session/bootstrap and chat requests time out into retryable errors; upstream model HTTP 429 responses no longer look like customer quota failures. Public site and health checks return 200, the API and dashboard are healthy, and the database, daemon, and tunnel were not recreated.
- Traein Polar sandbox verified 2026-09-12: sandbox organization `traein` has public monthly EUR products Coffee Club at EUR 5 and Pro at EUR 25, both with inclusive tax. Customer plan changes are enabled with `prorate`, customer email changes and multiple subscriptions are disabled, and raw API-version `2026-04` webhook `customer.state_changed` targets `https://traein.semyon.ie/billing/webhook`. The 30-day organization token has only `checkouts:write` and `customer_sessions:write`; token and webhook secret are stored only in mode-600 private files on the laptop/server and in the server stack environment. A public signed probe returned 202 and an unsigned probe returned 403. `POLAR_CHECKOUT_ENABLED=false` remains the global kill switch pending a signed-in sandbox checkout test and separate production Polar setup.
- Verified 2026-09-14: Jenkins job `irish-rail-nabber` now uses SCM `*/main` and the repository `Jenkinsfile`, replacing a stale inline pipeline. Persistent configuration is `server-stacks/jenkins/irish-rail-nabber/job-config.xml`, loaded by `seed-irish-rail.groovy`; it is excluded from the generic inline seed. Existing job properties and triggers were preserved.
- Verified 2026-09-14: the Irish Rail Jenkins candidate smoke network reserves `10.254.40.0/28`, checked against all 33 server Docker networks and host routes. Docker default address pools are exhausted. This subnet is for temporary validation containers only and is cleaned up after each test; do not allocate it to another service without updating the Jenkins job.
- Traein NTA realtime verified 2026-09-13: commit `882613e` and Jenkins build 88 are live. One collector alternates the NTA v2 TripUpdates and Vehicles operations through the shared PostgreSQL `nta_realtime` reservation, with one request every 61+ seconds and each data kind normally refreshing about every 122 seconds; extra-account sharding is deliberately not used. Production verification recorded Vehicles (559), TripUpdates (9,161 accepted), then Vehicles (553) at 63.9- and 61.3-second gaps, with healthy zero-restart containers. Public GraphQL and `/buses` showed a live feed, stop departures, route shapes and 553 vehicles across Dublin Bus, Bus Éireann, Bus Éireann Waterford and Go-Ahead. The active subscription key is stored only in the mode-600 server `stack.env`; rotate both keys supplied in chat when convenient because chat is not a durable secret channel.
- Use for: default agent work, fleet scouting, T3 Code headless, Docker-heavy local work.
- Caution: many Docker bridge networks are present; filter LAN information to `wlp59s0`, `tailscale0`, and known service ports when documenting the physical fleet.

- Siobhán NAS user verified 2026-08-25: `/export/nas/users/siobhan` (SMB share `siobhan`, her Windows PC is `10.0.0.164`). Home holds a large Desktop/Downloads backup set; no Google Takeout archive had arrived as of 2026-08-25 01:40 despite an active SMB browse session.
- Immich verified 2026-08-25 (on `server`): containers `immich_server` (ghcr release, port `0.0.0.0:2283`), `immich_postgres` (db `immich`, user `postgres`), `immich_redis`, `immich_cloudflared`. Data on NFS at `/mnt/media/immich/data` (`10.0.0.6:/nas` mounted at `/mnt/media` on server). Users: semyon, polina, pat, michelle, siobhanfox36@gmail.com ("Siobhán", id `b2c736f4-...`). Per-user import API keys are minted via temp-password + bcrypt swap through psql then restored; pattern used for Polina earlier and Siobhán on 2026-08-25.
- Siobhán quota incident verified 2026-08-25: her NAS subvolume had the default 5 GiB btrfs qgroup limit while she referenced 30.09 GiB, so all her SMB writes (including the awaited Google Takeout) silently failed. Kernel quirk (Debian 6.12 backports): `btrfs qgroup limit` returns EDQUOT while the group is over-limit — even raising/removing the limit fails. Fix pattern used: reflink-copy contents to a staging dir on toplevel (unlimited), delete originals, raise limit, reflink back, verify manifests both ways. Her limit is now 250G (user-set preference; polina=300G, pat/michelle=5G defaults). Daily snapshots of users/siobhan exist as extra recovery layer.
- NAS access model verified/repaired 2026-08-25: NFS exports rewritten by hand (`/etc/exports.bak-quota-audit-20260825` backup) — pool `/export/nas` restricted to `10.0.0.5` rw+no_root_squash (admin path); new `/export/shared` bind mount exported public rw (LAN+Tailscale, root_squash) along with `/export/scans`; shared + scans chmod 2777. Hand edits must be mirrored in OMV web UI or they get overwritten on next apply.
- NAS SMB shares completed 2026-08-25 via `omv-confdbadm update` + `omv-salt deploy run samba` (persistent, DB-backed): personal shares now exist for all six users (adam, semyon, siobhan, polina, pat, michelle), each valid-users owner+semyon with cross-user invalid exclusions; michelle also got a missing `users/michelle` sharedfolder entry. Quotas now: semyon/adam unlimited, polina 300G, siobhan 250G, pat 100G, michelle 5G (default, flagged for possible raise). Config DB backed up at `/etc/openmediavault/config.xml.bak-20260825-user-shares`. Known btrfs quirk: qgroup limit changes fail EDQUOT while over-limit.
- Siobhán takeout import pipeline verified 2026-08-25: watcher/importer at `server:~/.siobhan-takeout-import/run-import.sh` running in tmux session `siobhan-import`; official Immich CLI (`@immich/cli`, global npm, v2.2.79) with a JSON→XMP sidecar converter (`json-to-xmp.py`) since the official CLI has no takeout parsing (verified by dist grep + docs) but auto-detects `.xmp` sidecars; dedup is native checksum-based. API key in `api-key.txt` (chmod 600). Pipeline waits for stable upload, checksum-copies, extracts (multipart-aware), converts metadata, uploads with `--recursive --album`, verifies counts+name cross-check, quarantines then deletes source only on success. **COMPLETED 2026-08-25 19:20**: takeout-20260824T212107Z (11.1 GB) imported 3,248/3,248 assets (3,153 img + 95 vid), 8 year-albums, XMP sidecars applied; source verified by name crosscheck then deleted; staging cleaned. Gotchas learned: Google now names sidecars `<file>.supplemental-metadata.json`; Immich 3.x removed GET /api/assets (use /api/assets/statistics + POST /api/search/metadata, pageSize capped at 250); watcher baselines must not be captured while a partial upload exists.

### `nas`

- Verified 2026-09-14: 52 approved archive/data/model paths from `server` were checksum-verified and moved under `/export/nas/users/semyon/offload/server/home/semyon`, exposed on `server` at `/mnt/media/users/semyon/offload/server/home/semyon`. Original home paths are symlinks. This includes Polymirror historical datasets, archived analysis and obsolete Rust build output, emergency-model training data and older model versions, and three larger Ollama weight blobs. Active Polymirror state/C++ releases, the emergency model's v9 baked model and Python environment, and Qwen coder 3B remain local. The NAS destination base is mode 0700. Exact paths and receipts: `/home/semyon/code/labs/polymirror/docs/nas-offload-proposal-20260913.json` and `evidence/nas-offload-20260914/verification.json` in that project. The earlier Btrfs metadata stall had cleared before migration; its cause was not established.
- Role: NAS/storage host and Docker service host.
- Hostname: `nas`.
- Hardware: desktop chassis, model reported as `000-F4424-FBA015-2000`.
- OS: Debian 12 with backports kernel `6.12.73+deb12-amd64`.
- Access: `ssh nas` or `ssh 10.0.0.6`.
- Network: LAN `10.0.0.6/24`; Tailscale IP `100.65.148.17`; Tailscale DNS `nas.taild7128c.ts.net`.
- Status 2026-07-03: LAN ping and SSH worked; `tailscale ping 100.65.148.17` timed out from `server`.
- Re-verified 2026-08-12: LAN SSH works; direct Tailscale SSH remains unavailable from `server` while the NAS reports its documented Tailscale address locally.
- Agent tooling verified 2026-07-03: Codex `0.135.0`, Node `v22.18.0`, `npx 10.9.3`, Docker `29.5.3`; `tmux` unavailable; T3 Code unavailable; user linger `no`.
- Agent instruction scan verified 2026-07-06: no active `~/.claude/AGENTS.md`, `~/.claude/CLAUDE.md`, or `~/.codex/AGENTS.md` were found. Only `~/obsidian/AGENTS.md`, `~/obsidian/CLAUDE.md`, and temporary plugin instruction files were found under the home tree.
- Dotfiles audit verified 2026-07-06: no `~/dotfiles`, `~/.dotfiles`, or `~/.config/dotfiles` tree was found, and no key live config files from the stow packages were present in the read-only probe. Treat NAS as effectively unmanaged by the dotfiles repo today.
- Dotfiles cleanup verified 2026-07-07: `~/dotfiles` is now a clean HTTPS clone of `https://github.com/semyonfox/dotfiles.git` at `4040e89`. `git` is installed, but `stow` is unavailable, so NAS is clone-only and not deployed through Stow.
- Dotfiles sync verified 2026-07-07: NAS clone fast-forwarded to `9c63eab`; still clone-only because `stow` is unavailable.
- OBS canonical storage verified 2026-07-09 and moved 2026-07-13: single live source of truth for OBS recovery is `/export/nas/users/semyon/.obs/canonical`, with Linux at `linux/home/semyon/.config/obs-studio` copied from the repaired PC config and Windows at `windows/AppData/Roaming` copied from the Windows device dump. Both canonical scene sets retain Source Record state; Linux package note records `obs-studio 32.1.2-7.1` and `obs-source-record 0.4.8-1`. Stale OBS config/runtime copies under live `AppData/Roaming`, `device_dumps/windows_pc/AppData/Roaming`, and old `device_dumps/linux-laptop` OBS snapshots were deleted after canonical verification. NAS Btrfs snapshots and OBS recordings under `videos/OBS` were intentionally left alone.
- AI history crawl and cleanup verified 2026-07-26: all in-scope mutable
  storage for `semyon` plus `/export/nas/backups` was safely crawled, including
  device dumps/imports and the full targeted snapshot history. The immutable
  snapshot scan covered 1,669 provider roots and recovered 11 otherwise-missing
  Claude sessions; T3, Codex, OpenCode, Gemini, and Copilot snapshot variants
  were already logically covered. Ledgered cleanup then removed about 30.99 GB
  across 1,466 mutable historical targets. The exact target post-check is zero,
  and the residual manifest contains zero history/database candidates; remaining
  matches are configs, caches, source code, usage metadata, or archives.
  Immutable snapshots remain the recovery layer. Other NAS users were excluded.
- Services observed: rootless Docker user service; system services include Tailscale, Avahi, WSDD, Netdata, RPC/NFS-related listeners.
- Use for: storage/NAS diagnosis, container/service work, LAN proxy hop for the configured laptop SSH alias.
- Caution: treat disk, share, backup, RAID/ZFS/Btrfs/LVM, NFS/SMB, and Docker volume changes as high risk. Ask before modifying or restarting storage-related services.

### `pc`

- Role: desktop PC for GUI-adjacent work and LAN code work.
- SSH aliases: CachyOS uses `pc`, `cachy-pc`, or `semyons-pc` as user `semyon`; Windows uses `winpc` or `windows-pc` as user `foxsc`. Both reach `10.0.0.15`, but use distinct `HostKeyAlias` identities (`semyons-pc-cachy` and `semyons-pc-windows`) to prevent dual-boot key collisions.
- Linux SSH hostname: `semyon-pc-cachy`.
- Hardware: desktop chassis, model `MS-7C91`.
- VM readiness verified 2026-07-13: AMD Ryzen 5 5600G (6 cores/12 threads, AMD-V) with an integrated Radeon GPU plus the discrete RX 6600. KVM, `/dev/kvm`, and kernel IOMMU validation pass. Installed `qemu-full 11.0.2-3`, `libvirt 12.5.0`, `virt-manager 5.1.0`, `virt-viewer`, OVMF/UEFI firmware, `swtpm`, SPICE tooling, and AUR `looking-glass 2:B7-7`; `libvirtd.service` is enabled/active, the default NAT network is active/autostarted, and `semyon` belongs to `libvirt`. The iGPU is not currently exposed as a display controller, so BIOS iGPU enablement and moving at least one monitor cable to a motherboard video output remain prerequisites for clean RX 6600 passthrough. Linux storage has about 158 GiB free; the existing 931 GiB Windows NVMe partition is mounted at `/mnt/windows-drive`, has about 550 GiB free, and contains a Windows installation. Prefer a separate virtual disk over raw-booting that dual-boot Windows partition unless the additional activation, driver, filesystem, and rollback risks are explicitly accepted.
- OS from SSH: CachyOS, kernel `7.1.8-1-cachyos` (verified 2026-08-12); `ssh pc` lands here as `semyon-pc-cachy` (re-verified 2026-08-23). Windows side answers as `foxsc@10.0.0.15` when booted.
- Access flow: unless the requested OS is explicit, try `ssh pc` first (CachyOS). If it cannot connect or presents the Windows host-key identity, try `ssh winpc` (Windows). Never use raw `ssh 10.0.0.15`; the aliases keep each dual-boot OS on its own verified host-key identity. Windows alias/key verified 2026-08-26 after local fingerprint confirmation.
- Network: LAN `10.0.0.15/24`. Tailscale command was unavailable inside the Linux SSH environment on 2026-07-03.
- Tailscale inventory has a Windows device named `SEMYONS-PC` at `100.77.148.51` / `semyons-pc.taild7128c.ts.net`, offline on 2026-07-03. Do not assume this is the same booted OS as the Linux SSH session.
- Agent tooling verified 2026-07-09: `tmux 3.7b`, package-owned `codex-cli 0.143.0` from `openai-codex 0.143.0-1.1`, package-owned Claude Code `2.1.204-1`, Node `v26.4.0`, `npx 11.18.0`; Docker unavailable; user linger `yes`. Go is installed user-scoped at `~/.local/share/go` with `go` and `gofmt` symlinked into `~/.local/bin`; `go version go1.26.4 linux/amd64`; `GOBIN=/home/semyon/.local/bin`; `gopls v0.22.0` installed at `~/.local/bin/gopls` for Zed.
- Native AI CLIs verified 2026-07-25: fresh Bash and Zsh login shells resolve Anthropic's native Claude Code `2.1.220` through `~/.local/bin/claude` and the official OpenCode release `1.18.5` through `~/.opencode/bin/opencode`; both are user-owned executable ELF binaries and both self-update checks report current. Claude's launcher is the native installer's documented managed symlink into `~/.local/share/claude/versions/`; OpenCode's `~/.local/bin/opencode` is a plain convenience symlink to its documented `~/.opencode/bin` fallback location, not a wrapper. The active Codex is the user-global npm `@openai/codex@0.145.0` at `~/.local/bin/codex`; the Pacman `openai-codex 0.145.0-1.1` copy remains available at `/usr/bin/codex`. No global npm Claude Code or OpenCode package remains. The shared dotfiles Bash/Zsh `update` functions now use each native updater and resolve Codex's real target before choosing npm or Pacman handling. Inactive package copies `/usr/bin/claude` (`claude-code 2.1.220-1`) and `/usr/bin/opencode` (`opencode 1.18.4-1`) remain installed pending explicit sudo cleanup.
- AI restore cleanup verified 2026-07-26: the 13.91 GB
  `~/t3-restore-backups` tree was removed only after its two significant DBs
  passed migration/integrity checks and its 15 source-only projection turns
  were merged into server canonical T3. A post-check confirms the restore root
  is absent. PC live `.t3`, Claude, Codex, Gemini, OpenCode, and Copilot roots
  were intentionally retained for normal local use.
- Agent instruction scan verified 2026-07-06 and repaired the same day: `~/.claude/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.claude/fable-codex-orchestration.md` now resolve through `~/dotfiles/claude/.claude/` to the server-sourced Claude/Fable guidance. `~/.codex` exists but has no `AGENTS.md` by design for now. `~/dotfiles` is a Git repo with a dirty worktree; do not overwrite unrelated local changes when touching instruction files.
- Dotfiles audit verified 2026-07-06: `~/dotfiles` was on `master` at `origin/master` commit `49987dcf49dc` with a large dirty worktree during the audit. Public consolidation commit `6e83e0e` is now on `origin/master`, but the PC worktree was intentionally not pulled or restowed during the server-side consolidation. Active shell files, `~/.config/hypr`, `~/.config/waybar`, `~/.config/swaync`, `~/.config/mako`, `~/.config/starship.toml`, and `~/.local/bin` resolve into `~/dotfiles`; `~/.config/systemd/user` and `~/.config/dotfiles` are real directories with local state. Clean PC by reconciling local dirt first, then pull `origin/master` and deploy `stow --no-folding home claude hyprland waybar swaync rofi pc`.
- Dotfiles cleanup verified 2026-07-07: PC `~/dotfiles` is clean at `4040e89`, matching `origin/master`. The PC dirty worktree was preserved in stash `stash@{0}: pre-clean-20260707-105521-before-fd9cb98`, then fast-forwarded and deployed with `stow --no-folding home claude hyprland waybar swaync rofi pc`. PC Hyprland reloaded successfully after the `source =` comment fix. Waybar was restarted under `waybar.service`; the SwayNC bell module uses `~/.config/waybar/scripts/swaync.sh`, returns valid JSON, and no longer logs missing `notifications.sh` errors.
- SwayNC grouping verified 2026-07-07: public dotfiles commit `8c646a5` restores visible grouped-notification CSS for the shared SwayNC theme. PC `~/dotfiles` is clean at `8c646a5`; `swaync.service` is active and reloaded `~/.config/swaync/config.json` plus `style.css`. Test notifications confirmed control-center grouping into one collapsed stack, while popup toasts appear as separate vertically stacked windows. Test notifications were cleared afterward.
- Waybar tray verified 2026-07-07: public dotfiles commits `d84a4a3` and `9c63eab` remove the tray from the laptop Waybar profile and style the shared tray as a visible pill for the PC profile. PC `~/dotfiles` is clean at `9c63eab`; `waybar.service` was restarted and a screenshot check showed the PC tray icons on a dark pill background.
- Zed remote-source check verified 2026-07-06: PC `~/.config/zed/settings.json` has `ssh_connections` entries for `server` and `10.0.0.5`, with `/home/semyon` listed as a server remote project. From PC, `ssh server` and `ssh semyon@10.0.0.5` return hostname `server`; `ssh semyon@100.118.61.122` returned `No route to host`.
- Services observed: GUI session services, RustDesk, SSH, Avahi/systemd-resolved.
- RustDesk connect info verified 2026-07-05: RustDesk ID `8225647`, version `1.4.8`, system service active. Non-secret config shows rendezvous server `rs-ny.rustdesk.com:21116`; LAN IP is `10.0.0.15`. Do not store or print unattended passwords here.
- Display layout verified 2026-07-05: Hyprland `~/.config/hypr/monitors.conf` pins the AOC CU34G2XP ultrawide (`DP-2`, `3440x1440@180`, position `0x0`) as the default/main capture target, with the MSI G241 side monitor (`HDMI-A-2`, `1920x1080@60`, position `3440x0`) to the right. `monitors.json` marks the AOC descriptor as primary. Unknown/virtual fallback outputs are placed at `5360x0` so they do not become the `0x0` screen. Backups from the change use suffix `bak-mainmonitor-20260705163142`.
- Display HDR/DDC verified 2026-07-06: Hyprland `0.55.4` on AMD RX 6600 has the AOC CU34G2XP at `DP-2` running `3440x1440@180`, `bitdepth,10`, `cm,srgb` with current format `XRGB2101010`; the MSI G241 at `HDMI-A-2` stays `cm,srgb` and `XRGB8888`. `~/.config/hypr/userprefs.conf` explicitly sets `render:cm_enabled = true`, `cm_auto_hdr = 1`, `send_content_type = true`, `use_fp16 = 2`, and `keep_unmodified_copy = 2` for SDR desktop plus fullscreen HDR autoswitching. Backups from this change use suffix `bak-hdr-20260706160309`.
- Monitor DDC verified 2026-07-06: installed `ddcutil 2.2.7` and `i2c-tools 4.4`; `i2c-dev` is loaded and persisted in `/etc/modules-load.d/i2c-dev.conf`; user `semyon` is in group `i2c`. `ddcutil --display 2` maps to the AOC on `/dev/i2c-8` / `card1-DP-2`; `--display 1` maps to the MSI on `/dev/i2c-5` / `card1-HDMI-A-2`. AOC brightness VCP `0x10` is writable and currently `100`; standard contrast VCP `0x12` reports `50` and did not change after verified and no-verify writes, so do not assume contrast automation works.
- DaVinci Resolve maintenance on 2026-07-06: installed `inotify-tools` and user-local decode helper scripts at `~/.local/bin/davinci-decode-fix` and `~/.local/bin/davinci-decode-watch`; enabled `davinci-decode-watch.service` to watch `~/Downloads`, `~/Videos`, and `~/obsidian/images` and create `.resolve.wav` or `.resolve.mov` sidecars without modifying originals. For failing OBS AAC clip `/home/semyon/Videos/OBS/26-06-30_23-47-38.mp4`, created `/home/semyon/Videos/OBS/26-06-30_23-47-38.resolve.mov` with H.264 video copied and six AAC stereo tracks converted to 48 kHz `pcm_s16le`. Later on 2026-07-06, built `davinci-resolve-studio 21.0.2-1` from `~/Downloads/DaVinci_Resolve_Studio_21.0.2_Linux.zip`, removed conflicting `davinci-resolve 21.0.1-1`, installed Studio with `pacman -U`, and launched it through Hyprland with `hyprctl dispatch exec davinci-resolve-studio`. `davinci-ffmpeg-encoder-plugin 1.3.3-1` remains installed. Resolve Extras cache was populated from the Windows partition at `/mnt/codex-win-p3/ProgramData/Blackmagic Design/DaVinci Resolve/Support/Extras` plus the laptop `9cx2Nhyv...` package; DDM detected eight known packages and three extra cached packages in `/opt/resolve/Extras`. Do not record or expose Resolve license keys or activation secrets here.
- Screen capture prompt behavior verified 2026-07-05: `~/.config/hypr/xdph.conf` enables `screencopy.allow_token_by_default = true` and uses `hyprland-share-picker`, so XDPH should default to remembering the selected capture source for apps that support restore tokens. First-time or non-token-aware apps may still prompt.
- File handling verified 2026-07-12: Nemo is the registered default for `inode/directory` and `application/x-gnome-saved-search`; Dolphin was removed without removing shared dependencies. The PC Stow package owns `~/.config/mimeapps.list` and `~/.config/xdg-desktop-portal/hyprland-portals.conf`. Portal selection remains Hyprland-first with GTK fallback, and `org.freedesktop.impl.portal.FileChooser` is explicitly assigned to GTK. Existing browser and mail MIME associations were preserved.
- PDF editing verified 2026-07-13: installed signed CachyOS package `onlyoffice-bin 9.4.0-1` as the free PDF editor/form filler and removed evaluation package `pdfstudio-bin`. Launcher is `/usr/bin/onlyoffice-desktopeditors`; existing PDF MIME defaults were not changed.
- OBS Linux remap verified 2026-07-09: active OBS collection `Windows Import.json` and fallback `Untitled.json` under `~/.config/obs-studio/basic/scenes` contain Linux source IDs: PipeWire screen/window/camera, Pulse/PipeWire audio, browser, image, and scene sources. Profile `Untitled` records/streams with AMD VAAPI H.264 via `/dev/dri/by-path/pci-0000:12:00.0-render`; adjacent backups use suffix `backup-before-linux-remap-20260709-133650`. On 2026-07-09, the 1TB Windows partition `/dev/nvme1n1p3` was force-mounted read-only at `/mnt/codex-win-p3`, `obs-source-record 0.4.8-1` was installed from AUR, the plugin-manager `source-record` entry was enabled, and the Windows `source_record_filter` was restored onto Linux `Video Capture Device` in both active/fallback collections with backups suffix `backup-before-source-record-20260709-153014`. The Source Record filter settings match Windows: `record_mode=3`, `profile=main`, `rec_format=hybrid_mp4`, filename format `%CCYY-%MM-%DD %hh-%mm-%ss facecam`, and `others="Game Capture - Source Record"`. The PC RustDesk XDPH autopicker in `~/dotfiles/pc/.local/bin/hyprland-rustdesk-autopicker` delegates to `/usr/bin/hyprland-share-picker` while an `obs` process is running, because the unattended RustDesk picker otherwise returns a screen selection for OBS window-capture requests.
- Desktop app trials: Yank `v0.7.53` AppImage installed user-scoped on 2026-07-04 at `~/Applications/Yank/Yank.AppImage`; `~/.local/bin/yank` is a wrapper that preloads `/usr/lib/libwayland-client.so` to avoid the Tauri/WebKitGTK AppImage `EGL_BAD_PARAMETER` crash on Hyprland/Wayland. Vicinae `v0.22.3` installed user-scoped via the official script under `~/.local/lib/vicinae` with launcher `~/.local/bin/vicinae`; `vicinae.service` is enabled as a user service through `~/.config/systemd/user/vicinae.service`. Privileged Vicinae input support was completed with `uinput` module autoload and `cap_dac_override=ep` on `vicinae-input-server`. Hyprland bindings: `Super+Space` runs `/home/semyon/.local/bin/vicinae toggle`; `Super+V`, `Super+Shift+V`, and `Ctrl+Shift+Space` run `/home/semyon/.local/bin/yank --palette`; `Super+A` remains the Rofi fallback. The inherited Rofi `Super+Space` bind and cliphist `Super+V` binds were disabled, and cliphist `wl-paste` watchers were disabled/killed to avoid overlapping clipboard managers. Vicinae `telemetry.system_info` is disabled. Vicinae appearance on 2026-07-06 uses custom theme `catppuccin-rofi` at `~/.local/share/vicinae/themes/catppuccin-rofi.toml`, selected for dark mode in `~/.config/vicinae/settings.json`; the retuned `Catppuccin Grey` palette uses grey body colors (`#1E1F24`, `#24262D`, `#30323A`) with pink-purple window-style accents (`#CA9EE6`, `#F2D5CF`), `JetBrainsMono Nerd Font`, and launcher opacity `0.92`. Settings backups use suffix `settings.json.bak-catppuccin-*`; theme backups use suffix `catppuccin-rofi.toml.bak-grey-*`. Vicinae file indexing is restricted to `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Music`, `~/Pictures`, `~/Videos`, and `~/obsidian`, with `~/Applications`, `~/Projects`, `~/.cache`, `~/.local`, `~/.cargo`, and `~/.npm` excluded; cache was rebuilt and verified with 9,372 indexed rows and 0 rows outside the allowlist.
- Package-manager cleanup verified 2026-07-09: removed unowned root npm Codex install from `/usr/lib/node_modules/@openai` and `/usr/bin/codex`, installed repo `openai-codex 0.143.0-1.1`, and removed stale user-local shims/packages for Claude, Codex, Opencode, pnpm, `t3`, and the old `~/.local/lib/vicinae` script install. Interactive shells now resolve `claude`, `codex`, `pnpm`, `opencode`, `gemini`, `wrangler`, `vicinae`, and `t3code-nightly` to package-owned binaries, except the intentional `~/.local/bin/t3code-nightly` wrapper that adds `--password-store=gnome-libsecret` before calling `/usr/bin/t3code-nightly`. Updated package-owned `t3code-nightly-bin 0.0.29_nightly.20260709.765-1`, `vicinae-bin 0.23.0-2`, `cloudflared 2026.7.0-1.1`, and `eza 0.23.5-1.1`; `paru -Qu` was empty afterward. Cleared regenerable caches: `~/.cache/paru` shrank from about `59G` to `1.7M`, `~/.npm` to `52K`, and `/var/cache/pacman/pkg` from about `19G` to `9.7G`. User-level backup/manifest for tiny launcher files is at `~/.local/share/package-tidy-backup-20260709-130324` and was `32K` after cleanup.
- Hyprland shortcut verified 2026-07-13: the PC-specific `pc/.config/hypr/userprefs.conf` (sourced after shared keybindings) maps `Super+C` to `~/.local/bin/t3code-nightly`, which passes `--password-store=gnome-libsecret` to `/usr/bin/t3code-nightly`; `hyprctl reload` succeeded with no config errors and the live Hyprland binding table reports that wrapper.
- Hyprland Lua migration active 2026-07-30: after CachyOS upgraded Hyprland from `0.55.4` to `0.56.0` on 2026-07-22 and `0.56.1` on 2026-07-28, the compositor logged `Lua config not found, using legacy config`. Added the PC-owned `~/dotfiles/pc/.config/hypr/hyprland.lua`, deployed it through Stow, verified it with `luac -p` and `Hyprland --verify-config` (`config ok`), then restarted the graphical session. The new journal confirms `Using lua config found at /home/semyon/.config/hypr/hyprland.lua`; `hyprctl configerrors` is empty; all seven checked startup components run; the two-monitor geometry, refresh rates, 10-bit AOC format, and sRGB presets match the old session; and the live bind count remains exactly 117 with Lua-backed core bindings. Full pre-switch config rollback archive: `~/.local/state/hyprland-legacy-before-lua-20260730-121422.tar.gz`, SHA-256 `53547dfbcd5a619822fc51c4ef8baf426050cd3f0e35711e0a6ec61c02a624a9`.
- Hyprland Lua regression repair verified 2026-07-30: the first migration exposed two Lua-mode incompatibilities. Current `hyprctl dispatch` accepts Lua dispatcher expressions rather than legacy dispatcher names, breaking helper-script actions despite all 117 binds being registered; and applying Lua `blur = true` to Waybar blurred its full-width transparent layer surfaces into visible gray strips. Removed the Waybar layer blur (CSS remains transparent), replaced the Lua move-window bind's legacy subprocess dispatches with direct `hl.dsp.window.move` calls, corrected the default special-workspace actions, and migrated legacy dispatch calls in `dontkillsteam.sh`, `windowpin.sh`, `wallbashqt.sh`, and `keybinds_hint.sh`. Those four helpers now live durably under `~/dotfiles/pc/.local/share/bin/` and are Stow-linked into `~/.local/share/bin/`. A full-reset reload retained 117 binds and zero config errors; a fresh screenshot visibly confirms transparent bar surfaces; live Lua API checks, a Vicinae open/close, and a disposable Kitty launch/close passed. No remaining legacy dispatch calls were found in the active Hyprland/helper paths. Script rollback archive: `~/.local/state/hyprland-helper-scripts-before-lua-fix-20260730-122344.tar.gz`; original pre-Stow files: `~/.local/state/hyprland-helper-live-files-before-stow-20260730-1229/`.
- Hyprland surrounding-tool migration verified 2026-07-30: completed a changelog-driven audit against upstream 0.55/0.56 and current `hyprctl` documentation. Added Stow-owned generated overlays at `pc/.config/hypr/overrides/theme.lua` and `animation.lua`, loaded last by `hyprland.lua`; added `hyprland-theme-to-lua` and `hyprland-animation-to-lua`; and migrated `themeswitch.sh`, `swwwallbash.sh`, `animations.sh`, `wbarstylegen.sh`, `sysmonlaunch.sh`, `gamelauncher.sh`, and `steam-fix-notes.sh` away from legacy Hyprland config reads/writes and IPC. The initial overlay `require` mistakenly included `.lua`, producing a visible module-path error; corrected both imports to extensionless module names, reloaded, and re-ran `Hyprland --verify-config` (`config ok`). Final scan found no removed 0.55 options, legacy Hyprland `.conf` dependencies, or legacy `hyprctl dispatch/keyword` calls in active helper/config paths. Live dynamic config, rounding lookup, and temporary theme/animation generation tests passed; `hyprctl configerrors` remains empty with 117 binds. Legitimate configs for Hypridle, Hyprlock, Hyprpaper, and XDPH remain hyprlang as upstream explicitly retains that format for other Hypr tools. Remaining-helper rollback archive: `~/.local/state/hyprland-remaining-helpers-before-lua-20260730-123328.tar.gz`, SHA-256 `2adf00f766fc9e182b210b9970af2152274fcfcefbcc28ee9165eed4fe4cb78b`; original pre-Stow files: `~/.local/state/hyprland-remaining-helper-live-files-before-stow-20260730-1233/`.
- Vocalinux verified 2026-07-06: installed user-scoped with launchers `~/.local/bin/vocalinux` and `~/.local/bin/vocalinux-gui`; `~/.config/autostart/vocalinux.desktop` starts `/home/semyon/.local/bin/vocalinux --start-minimized`. Waybar `~/.config/waybar/config.jsonc` includes a `tray` module so `org.kde.StatusNotifierWatcher` is active; backup before tray insertion is `config.jsonc.bak-vocalinux-tray-20260706-204040`. `~/.config/waybar/style.css` styles the tray as its own Catppuccin pill; latest backup before that shape is `style.css.bak-tray-own-pill-20260706-204812`. Running service `vocalinux.service` registers `/org/ayatana/NotificationItem/vocalinux`, uses whisper.cpp tiny with Vulkan on the AMD RX 6600 XT, and the Wayland double-Ctrl shortcut is active through evdev. User `semyon` is in the `input` group.
- Local LLM setup verified 2026-08-29: user-local llama.cpp `cc83d7b` was built with Vulkan under `~/.local/src/llama.cpp`, with `llama-cli`, `llama-server`, and `llama-bench` linked in `~/.local/bin`. Official Qwen3-30B-A3B Q4_K_M is cached at `~/.local/share/llama.cpp/models/Qwen3-30B-A3B-Q4_K_M.gguf` (18,556,685,824 bytes, SHA-256 `0d003f6662faee786ed5da3e31b29c978de5ae5d275c8794c606a7f3c01aa8f5`). The final agent layout is one slot and six CPU threads with `-c 65536 -np 1 -t 6 -ngl 99 -cmoe -fa on -ctk q4_0 -ctv q4_0 -nkvo --rope-scaling yarn --rope-scale 2 --yarn-orig-ctx 32768 --override-kv qwen3moe.context_length=int:65536`. Keeping MoE experts and the 65K quantized KV cache in system RAM leaves total VRAM use near 5.52 GiB including the desktop, about 23 GiB system RAM available at idle, and avoids active swap pressure. The shorter 8K benchmark measured 94.07 prompt tok/s and 18.34 generation tok/s; a real 52,863-token OpenCode prefill measured 79.48 prompt tok/s and 2.36 generation tok/s at that depth, while the cached second turn completed in about 12 seconds and reused 52,868 tokens. `--load-mode none` is not viable because RADV fails model loading with insufficient command-submission memory. The OpenAI-compatible server and Web UI are reachable at PC `127.0.0.1:8080` and server `127.0.0.1:18080`, using provider/model `llama.cpp/qwen3-30b-a3b-q4` on PC OpenCode `1.18.25` and `pc-llama/qwen3-30b-a3b-q4` on server OpenCode `1.18.23`. Both advertise 65,536 context, 4,096 output, reasoning via `reasoning_content`, and tool calls. A PC OpenCode tool-call test emitted a valid `read` request and correctly hit OpenCode's external-directory permission boundary. The previous PC one-line config is retained at `~/.config/opencode/opencode.jsonc.bak-before-local-qwen-20260829`. User-local aria2 `1.37.0` was also installed for resumable segmented model downloads.
- Local LLM made durable/on-demand verified 2026-08-30: the original manual tmux sessions (`qwen3-30b-server` on PC, `qwen3-pc-tunnel` on server) were replaced with boot-persistent, socket-activated `systemd --user` chains (linger already enabled both hosts, confirmed still `Linger=yes`). PC: `llama-server-real.service` runs the actual llama-server bound to internal-only `127.0.0.1:8081` with the same flags as above; `llama-proxy.socket` (enabled, `Accept=no`) listens on the real public port `127.0.0.1:8080` and on first connection starts `llama-proxy.service`, whose wrapper `~/.local/bin/llama-proxy-launch.sh` starts `llama-server-real.service`, polls `/v1/models` until ready, then `exec`s `/usr/lib/systemd/systemd-socket-proxyd 127.0.0.1:8081` to bridge the inherited socket. `llama-idle-check.timer` (5 min interval) runs `~/.local/bin/llama-idle-check.sh`, which checks `ss` for established connections on 8080/8081 and stops `llama-proxy.service llama-server-real.service` after 1800s (30 min) with zero connections; activity resets the idle clock via `~/.cache/llama-proxy-last-active`. Server side mirrors this exactly: `qwen3-ssh-forward.service` runs `ssh -N -L 127.0.0.1:18081:127.0.0.1:8080 pc` (`Restart=on-failure`); `qwen3-tunnel.socket` listens on `127.0.0.1:18080` and `qwen3-tunnel.service` (`~/.local/bin/qwen3-tunnel-launch.sh`) starts the forward, polls `18081`, then bridges via `systemd-socket-proxyd`; `qwen3-idle-check.timer`/`.sh` apply the same 1800s teardown. Unit files live in each host's `~/.config/systemd/user/`. Verified end-to-end from fully cold (all four service instances `inactive`, both sockets/timers `active`/`enabled`): a single client request to server `127.0.0.1:18080` cascades server-tunnel to PC-proxy to real llama-server and completes in a reproducible ~4 seconds (measured twice), much faster than llama-server's own model-load benchmark would suggest. Idle teardown was force-verified on both hosts (fake old timestamp plus manual timer-service run) and correctly stopped only the on-demand service pairs while leaving both `.socket` units listening. No OpenCode config changes were needed; the public URLs/ports/provider names are unchanged from the note above.
- PC audio chain verified 2026-08-23: PipeWire 1.6.8 stack is spectrally transparent end-to-end — simultaneous differential pink-noise test (analog sink vs null-sink monitors) measured 0.00 dB in all octave bands; no EasyEffects/filter-chain/EQ installed, ALSA ALC897 controls all at 0 dB. "Bass boosted + clipping" complaint was caused by the default analog sink running at ~95–100% device volume overdriving the user's powered speakers/sub amp; fixed by `wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.70`. If distortion recurs at moderate volume, suspect speaker/sub hardware.
- PC NAS mount switched to SMB verified 2026-08-25: the morning export rewrite had restricted `/export/nas` to `10.0.0.5` only, leaving the PC's NFS automount of `10.0.0.6:/nas` silently showing an empty directory. Replaced the fstab entry with CIFS: `//10.0.0.6/semyon /mnt/nas cifs credentials=/home/semyon/.smbcredentials,...,_netdev,nofail,x-systemd.automount,x-systemd.idle-timeout=600`. Credentials file chmod 600 (password never recorded here). Verified mount, uid=1000 mapping, and write test. fstab rollback: `/etc/fstab.bak-cifs-20260825`. Note: Samba logons use a separate password from the Linux account.
- Use for: desktop/GUI tasks, local LAN jobs, high-performance interactive work if the user confirms the machine is free.
- Caution: because aliases include `winpc` but SSH currently lands in CachyOS Linux, verify the booted OS before making OS-specific changes.

### `laptop`

- Role: ThinkPad mobile machine; earlier probe found remote T3/Ollama listeners, but current startup setup is not fully verified.
- SSH aliases: `laptop`, `cachy-laptop`, `10.0.0.17`; current alias uses `ProxyCommand ssh nas nc %h %p`.
- Hostname from Tailscale SSH: `semyons-laptop`.
- Hardware: ThinkPad X1 Carbon Gen 9, laptop chassis.
- OS: CachyOS, kernel `7.1.2-3-cachyos`.
- Access: `ssh laptop` via the configured LAN/NAS proxy worked on 2026-07-04, failed from `server` earlier on 2026-07-06 with `No route to host`, then worked again later on 2026-07-06. Direct `ssh semyon@10.0.0.17` also worked on 2026-07-06. Direct Tailscale SSH to `semyon@100.127.128.15` worked on 2026-07-05 but timed out earlier on 2026-07-06; `tailscale status` showed the node offline, last seen about 16 hours earlier, and `tailscale ping 100.127.128.15` returned no reply.
- LAN: SSH config points to `10.0.0.17`; TCP/22 was reachable from `server` on 2026-07-04 but not on 2026-07-05 via NAS proxy.
- Tailscale: `100.127.128.15`, `semyons-laptop.taild7128c.ts.net`; MagicDNS did not resolve from `server`, raw IP worked. Prefer direct raw Tailscale SSH when LAN/NAS proxy fails.
- Agent tooling verified 2026-07-03: `tmux 3.7b`, Node `v26.4.0`, `npx 11.16.0`, Docker `29.6.1`; Codex unavailable.
- Agent instruction scan verified 2026-07-06 and repaired the same day: `~/.claude/AGENTS.md`, `~/.claude/CLAUDE.md`, and `~/.claude/fable-codex-orchestration.md` now resolve through `~/dotfiles/claude/.claude/` to the server-sourced Claude/Fable guidance. `~/.codex` exists but has no `AGENTS.md` by design for now. `~/dotfiles` is a Git repo with a dirty worktree; do not overwrite unrelated local changes when touching instruction files.
- Dotfiles audit verified 2026-07-06: `~/dotfiles` was on `master` at `origin/master` commit `49987dcf49dc` with a dirty worktree during the audit. Public consolidation commit `6e83e0e` is now on `origin/master`, but the laptop worktree was intentionally not pulled or restowed during the server-side consolidation. Active `~/.bashrc`, `~/.bash_aliases`, `~/.bash_functions`, `~/.gitconfig`, `~/.tmux.conf`, `~/.config/btop`, `~/.config/starship.toml`, `~/.config/hypr`, `~/.config/waybar`, and `~/.config/swaync` resolve into `~/dotfiles`; active `~/.zshrc`, `~/.zshenv`, `~/.profile`, `~/.local/bin`, and `~/.config/systemd/user` are local real files/directories. Untracked SSH config files exist under `~/dotfiles/home/.ssh`; do not read key material or stow them without explicit review. Clean laptop by reconciling local dirt first, then pull `origin/master` and deploy `stow --no-folding home claude hyprland waybar swaync rofi laptop`.
- Dotfiles cleanup partially verified 2026-07-07: laptop `~/dotfiles` reached clean `4040e89`, matching `origin/master`, and the laptop dirty worktree was preserved in stash `stash@{0}: pre-clean-20260707-105745-before-4040e89`. Real-file Stow conflicts were preserved at `~/dotfiles_stow_conflicts_laptop_20260707-110153`, then `stow --no-folding home claude hyprland waybar swaync rofi laptop` completed with a clean dry-run. `~/.config/waybar/config.jsonc` resolved to `~/dotfiles/laptop/.config/waybar/config.jsonc`. Follow-up is still needed for ignored local-only SSH/Cloudflare helper files because the laptop went unreachable before those could be restored out of the stash; LAN via NAS reported no route to `10.0.0.17:22`, direct Tailscale SSH to `100.127.128.15` timed out, and `tailscale status` showed the node offline/last seen about one day earlier.
- Laptop Waybar/Hyprland follow-up 2026-07-07: user reported laptop scaling wrong, unwanted laptop tray, and the same Hyprland config-file error. Public dotfiles commits `d84a4a3` and `9c63eab` remove tray from `laptop/.config/waybar/config.jsonc`; the tracked laptop monitor profile still sets `eDP-1` to scale `1.25`, and the tracked shared `hyprland.conf` has no inline comments on `source =` lines after `4040e89`. Live laptop verification/deployment was blocked: server direct LAN, NAS proxy, PC LAN, direct Tailscale `100.127.128.15`, `tailscale ping`, and Cloudflare hostnames `laptop-ssh.semyon.ie`/`ssh.semyon.ie` all failed.
- Laptop Waybar/Hyprland recovery verified 2026-07-07: direct Tailscale SSH to `semyon@100.127.128.15` worked again. Laptop `~/dotfiles` fast-forwarded from `4040e89` to clean `9c63eab`; live `~/.config/waybar/config.jsonc` no longer contains `tray`; Waybar was restarted through the Hyprland session. `hyprctl reload` returned `ok`, `hyprctl configerrors` was empty, and `hyprctl monitors all` reported `eDP-1` scale `1.25`.
- Services observed during the initial 2026-07-03 probe: T3 Code listening on `0.0.0.0:3773`; Tailscale PeerAPI on `100.127.128.15:62373`; Ollama on `127.0.0.1:11434`; Cloudflare Tunnel for laptop SSH; RustDesk; Mullvad VPN; KDE Connect. A later audit could not reach SSH, so do not document the laptop T3 startup method until rechecked.
- DaVinci Resolve maintenance on 2026-07-04: installed `davinci-resolve-studio-beta 21.0b2-3` and `davinci-ffmpeg-encoder-plugin 1.3.3-1`; package validation clean after correcting `/opt/resolve` directory ownership. Resolve user config and project metadata cache were corrected from `/root` cache/gallery paths to `/home/semyon`. A failing Opus-in-M4A clip was converted to `/home/semyon/obsidian/images/Recording 20260327095455.resolve.wav` for import. Installed `inotify-tools` and user-local decode helper scripts at `~/.local/bin/davinci-decode-fix` and `~/.local/bin/davinci-decode-watch`; enabled `davinci-decode-watch.service` to watch `~/Downloads`, `~/Videos`, and `~/obsidian/images` and create `.resolve.wav` or `.resolve.mov` sidecars without modifying originals. On 2026-07-06, built `davinci-resolve-studio 21.0.2-1` from `~/Downloads/DaVinci_Resolve_Studio_21.0.2_Linux.zip` under `~/.cache/paru/clone/davinci-resolve-studio`; after the laptop came back online, removed `davinci-resolve-studio-beta`, installed `davinci-resolve-studio 21.0.2-1` with `pacman -U`, and launched it through Hyprland. `davinci-ffmpeg-encoder-plugin 1.3.3-1` remains installed. Resolve Extras cache was synchronized with the PC after the PC imported the Windows cache; DDM detected eight known packages and three extra cached packages in `/opt/resolve/Extras`. Do not record or expose Resolve license keys or activation secrets here.
- Desktop app trials on 2026-07-04: Yank `v0.7.53` AppImage installed user-scoped at `~/Applications/Yank/Yank.AppImage`; `~/.local/bin/yank` is a wrapper that preloads `/usr/lib/libwayland-client.so` for Hyprland/Wayland. Vicinae `v0.22.3` installed user-scoped via the official script under `~/.local/lib/vicinae` with launcher `~/.local/bin/vicinae`; `vicinae.service` is enabled as a user service through `~/.config/systemd/user/vicinae.service`. Privileged Vicinae input support was completed with `uinput` module autoload and `cap_dac_override=ep` on `vicinae-input-server`. Hyprland bindings: `Super+Space` runs `/home/semyon/.local/bin/vicinae toggle`; `Super+V`, `Super+Shift+V`, and `Ctrl+Shift+Space` run `/home/semyon/.local/bin/yank --palette`; `Super+A` remains the Rofi fallback. The inherited Rofi `Super+Space` bind and cliphist `Super+V` binds were disabled, and cliphist `wl-paste` watchers were disabled/killed to avoid overlapping clipboard managers. Vicinae `telemetry.system_info` is disabled. Vicinae appearance on 2026-07-06 uses custom theme `catppuccin-rofi` at `~/.local/share/vicinae/themes/catppuccin-rofi.toml`, selected for dark mode in `~/.config/vicinae/settings.json`; the retuned `Catppuccin Grey` palette uses grey body colors (`#1E1F24`, `#24262D`, `#30323A`) with pink-purple window-style accents (`#CA9EE6`, `#F2D5CF`), `JetBrainsMono Nerd Font`, and launcher opacity `0.92`. Settings backups use suffix `settings.json.bak-catppuccin-*`; theme backups use suffix `catppuccin-rofi.toml.bak-grey-*`. Vicinae file indexing is restricted to `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Music`, `~/Pictures`, `~/Videos`, and `~/obsidian`, with `~/Applications`, `~/code`, `~/Projects`, `~/projects`, `~/.cache`, `~/.local`, `~/.cargo`, and `~/.npm` excluded; cache was rebuilt and verified with 56,908 indexed rows and 0 rows outside the allowlist.
- Vocalinux verified 2026-07-06: installed user-scoped with launchers `~/.local/bin/vocalinux` and `~/.local/bin/vocalinux-gui`; `~/.config/autostart/vocalinux.desktop` starts `/home/semyon/.local/bin/vocalinux --start-minimized`. Waybar `~/.config/waybar/config.jsonc` includes a `tray` module so `org.kde.StatusNotifierWatcher` is active; backup before tray insertion is `config.jsonc.bak-vocalinux-tray-20260706-191528`. `~/.config/waybar/style.css` styles the tray as its own Catppuccin pill; latest backup before that shape is `style.css.bak-tray-own-pill-20260706-204817`. Running service `vocalinux.service` registers `/org/ayatana/NotificationItem/vocalinux`, uses whisper.cpp tiny with Vulkan on Intel Iris Xe, and the Wayland double-Ctrl shortcut is active through evdev. User `semyon` is in the `input` group.
- Zed remote-source check verified 2026-07-06: laptop can `ssh server` and `ssh semyon@10.0.0.5` successfully. `~/.config/zed/settings.json` has an `ssh_connections` entry for `server` with `/home/semyon` listed as a remote project. Backup before this change: `~/.config/zed/settings.json.bak-server-remote-20260706180523`.
- Noctalia changeover landed 2026-08-23: laptop and PC both run the Noctalia shell (`noctalia` package; laptop `5.0.0_beta.8-1.1`, PC `5.0.0_beta.9-3.1`) over Hyprland, with waybar/swaync retired. Dotfiles `origin/master` `70e64a6` owns shared Noctalia config in the new `noctalia/` Stow package (TOMLs), `hyprland/` keeps the Hypr theme source, `home/` keeps `noctalia-lock`/`noctalia-idle-suspend`. Laptop starts noctalia via `laptop/.config/hypr/userprefs.conf` exec-once; PC via `pc/.config/hypr/hyprland.lua`; PC Super+L binds `noctalia-lock`. PC user services `waybar.service`/`swaync.service` disabled; hypridle/batterynotify/hyprpaper startups removed from PC lua (audio binds keep calling waybar scripts harmlessly). Pre-change stack preserved on branch `legacy-shell-stack` at `d2b559c`; laptop work history on branch `laptop-noctalia`.
- Stow conflict backups created 2026-08-23: real-file/directory collisions were moved aside on both hosts to `~/dotfiles_stow_conflicts_noctalia_20260823` (identical skill copies on laptop; PC copies of model-routing/ship-changes/visual-evidence moved there too). One unversioned PC-local variant of `~/.config/btop/themes/noctalia.theme` differed from the repo version and was removed during stow repair without backup.
- Laptop access update verified 2026-08-23: direct Tailscale SSH `semyon@100.127.128.15` works; the `ssh laptop` NAS-proxy alias timed out during banner exchange. Prefer Tailscale path first while that persists.
- Laptop access reverified 2026-09-09: direct Tailscale SSH `semyon@100.127.128.15` works; `ssh laptop` through the NAS proxy returned `No route to host`. Use the direct Tailscale path for maintenance until the LAN route is repaired.
- Access diagnostic observed 2026-09-09 12:14 IST: the Tailnet path is healthy (`tailscale ping` reached the laptop directly in 12 ms and its PeerAPI returned HTTP 200), but TCP ports 22 and 3773 both timed out from `server`. This is consistent with a laptop-side firewall or a Tailnet ACL blocking those service ports, rather than an offline laptop. Recheck before assuming direct Tailscale SSH works.
- Tailscale access repair verified 2026-09-09: laptop `tailscale debug prefs` showed `ShieldsUp: true`, which blocked inbound Tailnet services despite `sshd` and T3 listening on `0.0.0.0`. Set it to `false` with `tailscale set --shields-up=false` on the laptop. Direct SSH from `server` to `100.127.128.15:22` and HTTP access to `100.127.128.15:3773` then succeeded. UFW remained active and was not changed; prefer the direct Tailscale path going forward.
- OpenWhispr AppImage verified 2026-09-06: installed user-scoped at `~/Applications/OpenWhispr/OpenWhispr.AppImage`, with `~/.local/bin/openwhispr` (and `openwhisper` symlink) launcher scripts, app icon at `~/.local/share/icons/hicolor/512x512/apps/openwhispr.png`, and desktop entry `~/.local/share/applications/openwhispr.desktop` for Noctalia/Vicinae/Rofi launcher integration.
- Steam runtime recovery verified 2026-09-09: four orphaned `zenity --progress` dialogs titled "Unpacking Steam Runtime" from separate September launches consumed about 200% CPU after their archive extraction had completed but Zenity never exited. Each stale Hyprland Steam scope held only Zenity and an idle `srt-logger`; no Steam client, game, or extractor remained. The installed Steam/Zenity packages were intact and current, 98 GB was free, and the archive MD5 was valid. Stopping those four user scopes let Steam finish its intended runtime swap. The live runtime marker now matches its archive checksum, and Steam restarted into its normal client update without Zenity.
- OpenWhispr Dictation Cleanup verified 2026-09-09: configured the Self-Hosted provider to the laptop-local Ollama OpenAI-compatible endpoint `http://127.0.0.1:11434/v1`, with `gemma3:4b` selected and no API key. The app refreshed its available model list from the loopback service, and a synthetic punctuation-cleanup request completed successfully through that model. This is separate from the app's local Whisper transcription model.
- Hyprland Lua and IBus warning repair verified 2026-09-11: direct Tailscale SSH reached the laptop on CachyOS kernel `7.2.4-3-cachyos` with Hyprland `0.56.2`. The laptop branch had never received the unpushed server-side Lua draft, and `~/.config/hypr/hyprland.lua` was absent, so the active session logged a legacy-config fallback. Ported corrected `common.lua` and laptop `hyprland.lua` files into the laptop worktree without touching its existing dirty changes, Stow-linked them, retained the 1.25 eDP scale and `altgr-intl` layout, and added Noctalia 5.1's generated `noctalia.lua` theme hook. Default `Hyprland --verify-config` now selects the Lua entry point and reports `config ok`; the current graphical session remains on its original `.conf` until the next login. The visible IBus popup came from Vocalinux `0.13.0b0` spawning legacy `ibus-daemon -x -d -r` under Wayland. Upgraded Vocalinux user-locally to stable `0.16.1`, restarted only its autostart unit, and confirmed it uses `wtype` without any IBus daemon or UI process. Moved the stale Fcitx environment file out of `~/.config/environment.d` because no Fcitx package or process exists. Rollback copy: `~/.local/state/laptop-warning-fix-20260911-1934`.
- Hyprland Lua parity follow-up verified 2026-09-11: a directive-by-directive audit found the laptop's effective compositor settings are near-1:1 but exposed two real portability leaks. Moved the PC-only HDR/render block out of shared `common.lua` and into the PC entry point, and made both host entry points use Noctalia 5.1's generated `noctalia.lua` palette when present with an equivalent static fallback for clean deployments. The laptop passed `Hyprland --verify-config` with both the generated-module and fallback paths (`config ok` each). Its current OpenWhispr-managed bind file is intentionally empty, so the Lua config correctly has no F8 bind. The retired HyDE/Rofi/Waybar/Wallbash selector shortcuts are now disabled only in the laptop Lua profile because their helpers edit inactive `.conf` files and conflict with Noctalia ownership; PC behavior remains enabled by default. Rollback copy: `~/.local/state/hyprland-lua-parity-20260911-7hfmri`.
- Vocalinux removal verified 2026-09-11: stopped its generated user autostart unit and permanently removed its user-scoped venv/models, source checkout, configuration, launchers, autostart/menu entries, icons, and Vocalinux-only rollback copy (about 575 MB of files). No Vocalinux unit, process, or named user artifact remains. OpenWhispr and Noctalia were left intact; the system `ibus` package and `input` group membership were not changed.
- Helium browser verified 2026-09-13: `/usr/bin/helium-browser` is Helium `0.17.0.1` on Chromium `153.0.8010.36`. Its wrapper reads `~/.config/helium-browser-flags.conf`; the Squaredle Solver is loaded from `~/.local/share/helium-extensions/squaredle-solver` through one appended `--load-extension` flag. Existing flags were preserved. The packaged solver was updated that day with persistent positive/negative word caches and board-aware dictionary filtering; its remote `content.js` checksum matched the built package. Helium remains running with `--restore-last-session`; restart it only when the user is ready to load the updated code.
- Use for: mobile-machine troubleshooting and, after re-verification, remote T3/Ollama experiments.
- Caution: Codex CLI is not installed or not on `PATH` here as of 2026-07-03. Use T3 Code or install/update Codex only with the user's approval.

### Phones

Phones are lower priority for agent work and have no documented SSH path.

- Samsung SM-A546B: Android Tailscale entry `samsung-sm-a546b.taild7128c.ts.net`, `100.84.250.104`; expired/offline on 2026-07-03.
- Xiaomi 11T Pro: Android Tailscale entry `xiaomi-11t.taild7128c.ts.net`, `100.104.248.28`; offline on 2026-07-03.

### Router

- Default gateway: `10.0.0.1`.
- Reachability: ping OK from `server` on 2026-07-03.
- Unknowns: model, admin URL, credentials, DHCP reservations, port forwards, Wi-Fi settings.
- Rule: do not change router settings, port forwards, DHCP, DNS, firewall, VPN, or Wi-Fi without explicit confirmation and a rollback plan.

## Unidentified LAN Neighbors

Observed via `ip neigh` on `server` on 2026-07-03. These may be phones, IoT devices, containers bridged through the host, or transient clients.

- `10.0.0.4`
- `10.0.0.189`
- `10.0.0.200`
- `10.0.0.221` appeared as a failed neighbor entry in a later scout.

Do not treat these as fleet members until identified through the router DHCP table, mDNS/Avahi, ARP vendor lookup, or user confirmation.

## Recommended Follow-ups

- Add a direct Tailscale SSH host entry for the laptop, for example `Host laptop-ts` pointing at `100.127.128.15`, because MagicDNS did not resolve from `server`.
- When the laptop is reachable again, check ignored local-only paths that may have dangling symlinks after the 2026-07-07 stow cleanup: `~/.ssh/config`, `~/.ssh/config.d/`, `~/.local/bin/cf-access-ssh`, and `~/.config/systemd/user/{cloudflared-laptop-ssh.service,sshd-cloudflare.service,swaync-local.service}`. If needed, restore them from `~/dotfiles` stash `pre-clean-20260707-105745-before-4040e89` third parent into real home paths, not into the public repo.
- Install or enable `tmux` on `nas` if long-running agent sessions will happen there.
- Decide whether `pc` should have Linux-side Tailscale enabled, because the current Tailscale PC entry appears to describe a Windows/offline state.
- Fill in router model/admin URL and NAS storage layout after user-approved inspection.
- Re-audit the laptop's T3 Code startup path when it is reachable; only an earlier listener was verified, not its service/enable mechanism.
- Add machine-specific recovery notes only after confirming no secrets are included.


## Storage audit, verified 2026-09-05

- All four Linux hosts were reachable through their documented SSH aliases, including the laptop LAN/NAS-proxy route. No access configuration was changed.
- Server: WD Blue SN570 500 GB, ext4 root and FAT EFI. PC: SK hynix PC401 512 GB holds unlocked LUKS/Btrfs Linux; WD Black SN850X 1 TB holds Windows, with the main NTFS partition mounted through ntfs3. Laptop: Micron 2300 512 GB with LUKS/Btrfs.
- NAS: four Seagate ST4000VN006 4 TB members, Btrfs RAID10 for data, metadata and system. Share bind aliases refer to this one pool. Active root and EFI are on the Patriot P300 128 GB NVMe. An additional 4 GB flash disk has inactive EFI/ext4/swap partitions; its ext4 filesystem has zero ordinary-user available space. Both flash filesystems were inspected through temporary read-only mounts, with ext4 journal replay disabled.
- Health counters: laptop reports one NVMe media/data-integrity error and one Btrfs corruption event. Its last recorded scrub was 2026-02-13 and reported no errors. These cumulative counters do not establish whether a current fault remains. NAS member Btrfs error counters are zero and the 2026-08-29 scrub completed without errors. PC has zero Btrfs device errors but no completed scrub statistics.
- PC Windows metadata checks consistently fail on three entries in the Installer directory, with two ESTALE and one EINVAL from ntfs3. Native Windows validation remains a follow-up; the Linux result alone does not distinguish a driver issue from filesystem damage. Windows EFI and recovery partitions were also scanned using temporary read-only mounts; NTFS-3G recovery was disabled.
- Task reports are device-local under `/home/semyon/storage-audit-20260905/`. NAS historical snapshots use Btrfs qgroup accounting; laptop and PC snapshot directory references were enumerated. No cleanup, repair, new scrub/self-test, balance, service restart, or sudoers change was performed. Credentials were not stored in reports or inventory.

### Storage cleanup follow-up, verified 2026-09-05

- Authorized disposable caches were removed from all four hosts; Windows JetBrains program directories and dedicated settings/data were removed offline from the PC NTFS volume. Native Windows uninstall registration was not edited. Docker, backup repositories, snapshots and model stores were preserved. Exact deletion manifests and findings are under each host’s `storage-audit-20260905/cleanup/`.
- Both PC and laptop backup services last failed on September 5; direct Restic metadata lists show their newest successful snapshots on August 24. Their scripts expect `/mnt/nas/users/semyon/restic/...`. PC currently mounts the user SMB share at `/mnt/nas`, with its repository accessible at `/mnt/nas/restic/semyon-pc`; laptop mounts the NFS `/nas` export but that mounted directory appears empty. No mount or backup configuration was changed. Fixing backup access is the next storage priority.
- The large anonymous Docker volume attached to `irish_rail_db` contains the live PostgreSQL 18 cluster under `/var/lib/postgresql/18/docker`. Its separately named volume mounted at `/var/lib/postgresql/data` is nearly empty. Never infer which database volume is live from its name alone.
- Laptop cache removal showed substantial Btrfs snapshot retention: about 76 GB of file references removed but only about 4 GB recovered immediately. Snapshot policy was left unchanged.

### Docker and NAS staging cleanup, verified 2026-09-05

- The server cleanup ran while the Jenkins executor was idle. It cleared 4.259 GB of Docker engine build cache, 9.89 GB of Jenkins BuildKit cache, about 6.4 GB of exported Jenkins caches, and 2.057 GB of dangling image layers. It removed three stopped build/test containers and two E2E test volumes. Live application volumes and tagged rollback images remain. Server available space increased from about 53.2 GB to 78.0 GB.
- Three incomplete server-backup staging trees dated August 22, 23, and 25 were removed from the NAS. They represented 56.796 GB of directory references across about 135,000 files. The completed September 4 generation and its `COMPLETE` marker remain intact. Btrfs snapshots retained the deleted blocks, so the array showed no measurable free-space increase.
- After cleanup, Docker reported 51.88 GB of images, 21.07 GB of volumes, 5.734 GB of container writable layers, and zero build cache. The live Irish Rail PostgreSQL volume, Jenkins home, Open WebUI, application databases, 338 MB of unreferenced volumes, and tagged release/rollback images were preserved.

### Foghlaim Jenkins deployment, verified 2026-09-08

- Server Jenkins job `foghlaim` now uses Pipeline script from SCM for `semyonfox/foghlaim`, `*/main`, `Jenkinsfile`, existing credential ID `github-pat`, and GitHub push trigger. Previously it used an untriggered bootstrap snapshot despite successful webhook deliveries.
- Persistent definition: `server-stacks/jenkins/foghlaim/job-config.xml`, loaded by `jenkins/init.groovy.d/seed-foghlaim.groovy`. Previous non-secret job/seed configuration retained under `jenkins/foghlaim/recovery/20260908-scm-switch/`. No Jenkins restart required.
- Build #7 automatically followed the packaging-fix merge and deployed commit `319a92cfc4f45f08040d126f10994d652ef77576`. Container healthy; public health, resources, dictionary search, dataset, licence and provenance URLs returned 200. Database migrations and live billing configuration were not changed.

### Branchroom hosting, verified 2026-09-08

- `server` runs `1.28.0+dev-406-ga94b5ca6bf-branchroom-scoped3`, including uncommitted scoped-access changes, through enabled user systemd service `branchroom.service`, bound to LAN address `10.0.0.5:3080`. No public tunnel or DNS entry added.
- Deployment: `/home/semyon/.local/share/branchroom`, self-contained binary, separate ordinary/restricted repository directories, SQLite configured. Branchroom enabled; environment materialization and Actions disabled.
- Setup is complete. Physical laptop Helium checks passed for owner, synthetic user, anonymous access, grant revocation, GitHub import, public PR merge, restricted merge pushes and fake `.env` isolation. The synthetic account and its access were removed. Deployment notes and screenshots are under `/home/semyon/.local/share/branchroom/README.md` and `qa-20260908/`.
- SQLite schema remains version 358. The original binary is retained as `bin/gitea.before-scoped-access`; `/home/semyon/.local` is now `0755` to satisfy restricted-store ancestor checks. Internal HTTP callbacks accept literal IPs assigned to the same host; remote HTTP remains rejected. Configuration contains generated secrets; do not inspect or copy it.

### Laptop Java development, verified 2026-09-08

- OpenJDK 26.0.2.1 installed user-scoped at `~/.local/share/jdks/openjdk-26.0.2.1`, selected by `~/.local/share/jdks/current`. Extracted from the official Arch extra JDK package after pacman-key signature verification; system JRE remains unchanged. This user installation is not updated by pacman.
- Laptop dotfiles `home/.bashrc` and `home/.zshrc` conditionally set JAVA_HOME and prepend this JDK bin directory. Fresh Bash and Zsh resolve java, javac and jar correctly.
- Existing Zed Java extension 6.8.26 configured to use the same JDK; actual Zed startup downloaded JDTLS 1.61.0 and reached ServiceReady on CT2110 assignment10. Global Java compile/run tasks and debug launch config are sourced from `dotfiles/laptop/.config/zed/` via individual symlinks.
- Compilation, program execution, executable JAR, JDTLS initialization, and Java Debug breakpoint/local-variable/continue checks passed. The full debugger check used the previously cached JDTLS 1.57.0; a repeat on 1.61.0 initialized successfully but its final output was lost across session resumption.
- Existing IntelliJ Java 26 early-access JDKs retained. No system package changes, commits, or unrelated dotfiles changes made.

### Swim database recovery, verified 2026-09-08

- Production `pg-db` was stopped with a Docker address-in-use error while
  `swim-backend` restart-looped. The database reserves `172.20.0.2` on
  `uisce_uisce_default`; the backend had also received that address dynamically.
- With user approval, stopped the failing backend, detached its data-network
  attachment, started the existing database container, then reattached and
  started the backend. Preserved `uisce_pg_db_data`. PostgreSQL accepted
  connections and backend `/health` returned 200 with database connected.
- This repairs the running containers. Static-address reservation and startup
  ordering should be checked before any future network recreation or host reboot.

### Oghma download proxy sizing, verified 2026-09-14

- Server container `oghma-nginx` now has a 128 MiB RAM ceiling, 192 MiB combined RAM/swap ceiling, and two nginx workers. The previous 64 MiB limit with automatic worker count caused memory pressure and extremely slow APK downloads.
- Persistent source is `/home/semyon/server-stacks/oghma/stack.yaml`; container labels still reference an obsolete `docker-compose.yml`. Global nginx configuration is persisted in `oghma/nginx/main.conf`. Operational evidence and recovery files are linked from `/home/semyon/server-stacks/oghma/nginx/README.md`.
- One restart occurred while old workers drained during the change. Subsequent three simultaneous public APK downloads passed checksum verification without new OOMs or restarts; production and development health checks passed.

### Laptop GNS3 installation, verified 2026-09-15

- GNS3 GUI and server 3.0.6 run locally in the `gns3-gui` pipx environment on CachyOS, with PyQt6 and Python 3.14.7. Commands are `~/.local/bin/gns3` and `~/.local/bin/gns3server`. The AUR GNS3 packages pointed to 3.1.0a5 during installation, so the stable PyPI release was selected.
- Installed qemu-full 11.1.1, libvirt, xterm, uBridge 1.2.1, Dynamips 0.2.23 and VPCS 0.8.3; Wireshark and inetutils were already available. QEMU KVM startup passed, and two VPCS nodes exchanged three pings through uBridge. The temporary test project was deleted.
- Server binds only to 127.0.0.1:3080. Laptop dotfiles contain `laptop/.config/GNS3/3.0/gns3_server.conf` and `laptop/.local/share/applications/gns3.desktop`, symlinked into the user environment. GUI starts its own server; no persistent boot service was enabled. Docker remains inactive. Vendor router images were not installed.

### Oghma production CI gate, verified 2026-09-15

- `oghma-prod` now requires the `build` GitHub check on its exact `main` commit. The removed `lint` workflow previously blocked deployment; `test` and smoke E2E run on PRs/dev, not main pushes.
- Updated both `/home/semyon/server-stacks/jenkins/oghma-prod/Jenkinsfile` and the live inline job definition without restarting Jenkins. Previous source retained as `Jenkinsfile.before-ci-gate-20260915`; previous live definition retained under the job directory as `pipeline-before-ci-gate-20260915.groovy`.
- Build #113 succeeded and deployed app and worker revision `2cb55d1f9b9e9381591fd11a6948a7da2849dffa`. Live smoke passed and public `/api/health` returned `status: ok`.

### Jenkins builder registration, verified 2026-09-16

- Oghma production #114 failed because `jenkins-cache` registration was lost from the ephemeral `/home/jenkins/.docker/buildx` path after agent recreation. Existing container `buildx_buildkit_jenkins-cache0` and its state volume were intact.
- Re-registered that same node without replacing its container or cache. Agent Compose now sets `BUILDX_CONFIG=/home/jenkins/cache/buildx`, covered by existing `jenkins_jenkins_build_cache`. Production pipeline sets the same path explicitly for the current agent and has an idempotent `Prepare Docker Builder` stage before parallel image builds.
- Source and live production pipeline updated, prior definitions backed up with `before-buildx-20260916` names. No Jenkins/agent restart performed. Production #115 deployed `e380694bd1f2f705c046be797e34c5828c946e95`; live smoke and public health passed.

### Laptop Unity and Zed, verified 2026-09-16

- Unity Hub 3.21.1 and Editor 6000.6.0f1 are the retained installations. Removed the leftover 2022.3.62f1 Editor binaries under `Applications/BedroomTools`; archived projects were not migrated.
- Red Scene-view rendering blocks on Intel Iris Xe under OpenGL disappeared with Vulkan. Both `/home/semyon/mars` and `/home/semyon/Unity/StarTrekEnterprise` now explicitly select Vulkan for Linux. A normal restart verified the setting without CLI overrides.
- `StarTrekEnterprise/Assets/Scenes/MarsPhysics.unity` uses Rigidbody central gravity and tilted angular velocity. Ten-orbit PhysX validation passed with 0.1674% maximum radius deviation; actual Play-mode orbital movement and spin were observed. Validator restores `Physics.simulationMode`; normal project mode is FixedUpdate, serialized as 0.
- Zed 1.19.2 uses `/usr/bin/zeditor`, C# extension 1.2.2, Roslyn 5.12 and .NET SDK 10.0.112. Unity external-editor preferences are configured; project `Assets/Editor/ZedIntegration.cs` regenerates SDK-style C# projects from the existing Unity IDE package. The solution built, and a Roslyn hover probe resolved `UnityEngine.Rigidbody`. Double-clicking EnterpriseCinematic.cs in Unity successfully opened that script in the Zed project.
- Laptop dotfiles contain `laptop/.local/share/applications/mars-physics.desktop`, linked into the application launcher. `README-MarsPhysics.md`, `Validation/`, and `Recovery/20260916/` are in the Unity project.
- Enterprise cinematic playback verified after reconnecting: ship model, atmosphere, starfield, title and wide shots render correctly; V switches to physics overview and R replays the camera sequence. Unity Console showed zero errors after playback. Evidence is saved under the project Validation directory.
- Current Hyprland Lua control: use `hyprctl -i 0 eval 'hl.dispatch(hl.dsp.focus({window="address:..."}))'`, `hl.dsp.cursor.move({x=...,y=...})`, and `hl.dsp.send_shortcut({mods="SHIFT",key="space"})`. Coordinates are logical at scale 1.25. Xdotool pointer movement does not reliably move the compositor cursor; move the Hyprland cursor in logical coordinates, then set xdotool mousemove to the corresponding physical coordinates before clicking.

### Laptop CT3531 GNS3 course setup, verified 2026-09-16

- Course PDF requires GNS3 2.2.54 and remote compute `10.226.255.1:3080`, reachable only on CS building wired/lab Wi-Fi, not Eduroam. Verified remote version 2.2.54. PDF downloaded to laptop `~/Downloads/CT3531 - GNS3 Installation and Setup V4.pdf`.
- Separate Python 3.12 environment `~/.local/share/gns3-ct3531` contains GUI/server 2.2.54 and PyQt5. Launcher `GNS3 CT3531 (2.2.54)` uses Qt xcb. Local controller remains loopback `127.0.0.1:3082`, with local project topology and `nuig-cs` remote compute. Previous 3.0 installation/projects retained; its launcher is labelled `GNS3 3.0 (previous local setup)`.
- User approved a narrow routing exception after Tailscale exit routing intercepted university-server traffic. Priority 5200, destination `10.226.255.1/32`, table main/254, persisted in NetworkManager `CS-GroundFloor` only. Verified server traffic uses Wi-Fi gateway while SSH to server stays on Tailscale. Other campus connection profiles may need an equivalent approved exception.
- Template `MikroTik CHR 7.16 - CT3531` uses university image `chr-7.16.img`, four virtio Ethernet adapters, 384 MB RAM. Setup-check router and VPCS booted remotely; serial console and three ICMP replies passed. Test nodes stopped afterward. Local test project ID `7f9c7cc0-9c17-41e0-ab2f-b16ea1e52334`; notes, rollback and evidence in laptop `~/GNS3/ct3531-setup/`.
- Same-day follow-up: at user request, uninstalled pipx GNS3 3.0.6, consolidated to one `GNS3 CT3531 (2.2.54)` launcher in `gns3.desktop`, and added Stow-backed `gns3`/`gns3server` command wrappers pointing at the course environment. Project data and old settings retained. Verified both commands report 2.2.54 and both computes remain connected. Newer stable 2.2 controller code rejects a 2.2.54 compute version mismatch; 3.0.6 uses incompatible v3 APIs.

### Uisce private UI preview, verified 2026-09-21

- `server` Tailscale Serve HTTPS port `8444` proxies loopback `5175`, tailnet only: `https://server.taild7128c.ts.net:8444/`. No Funnel/public exposure.
- Containers `uisce-preview-web` and `uisce-preview-api` use the isolated `uisce-ui-validation_default` network and synthetic `swim-e2e-postgres` dataset. They do not use live SWIM data. All three restart unless stopped.
- Non-secret operations/rollback notes: `~/.local/state/uisce-preview-20260921/README.md`. Do not print or copy the adjacent private API environment file. Verified HTTPS, actual sign-in and authenticated mobile training through the private URL.
