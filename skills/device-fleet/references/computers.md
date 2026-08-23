# Semyon's Device Fleet

Last refreshed: 2026-08-12 from `server` using non-sudo local and SSH probes, plus prior documented maintenance work.

This file is the canonical inventory for the `device-fleet` skill. Do not store passwords, private key material, Tailscale auth keys, recovery codes, or other secrets here. Sudo passwords are provided by the user per task when needed and are never persisted.

## Operating Model

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

| Device | Role | SSH / Access | LAN | Tailscale | Status notes |
| --- | --- | --- | --- | --- | --- |
| `server` | Control node, agent host, T3 Code headless | `ssh server` | `10.0.0.5` | `100.118.61.122`, `server.taild7128c.ts.net` | LAN and Tailscale local; T3 systemd service active |
| `nas` | NAS/storage, Docker services, proxy jump for laptop LAN alias | `ssh nas` | `10.0.0.6` | `100.65.148.17`, `nas.taild7128c.ts.net` | LAN SSH works; Tailscale ping timed out |
| `pc` | Desktop PC, GUI/RustDesk, code work on LAN | `ssh pc`, `ssh winpc`, `ssh semyons-pc` | `10.0.0.15` | Windows tailnet entry `100.77.148.51`; Linux SSH env has no Tailscale | LAN SSH works (CachyOS re-verified 2026-08-23); which OS is booted decides the endpoint |
| `laptop` | ThinkPad/CachyOS mobile machine, remote T3/Ollama | `ssh laptop` via LAN/NAS proxy; direct Tailscale `ssh semyon@100.127.128.15` when online | `10.0.0.17` | `100.127.128.15`, `semyons-laptop.taild7128c.ts.net` | LAN SSH worked on 2026-07-04; direct Tailscale SSH timed out and Tailscale listed the node recently offline |
| Android phone: Samsung SM-A546B | Low-priority mobile device | No SSH documented | Unknown | `100.84.250.104`, `samsung-sm-a546b.taild7128c.ts.net` | Offline/expired Tailscale entry |
| Android phone: Xiaomi 11T Pro | Low-priority mobile device | No SSH documented | Unknown | `100.104.248.28`, `xiaomi-11t.taild7128c.ts.net` | Offline Tailscale entry |

## SSH Config Snapshot

Source: `/home/semyon/.ssh/config`, read 2026-07-03.

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

Host pc winpc semyons-pc 10.0.0.15
    HostName 10.0.0.15
    User semyon
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

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
- Use for: default agent work, fleet scouting, T3 Code headless, Docker-heavy local work.
- Caution: many Docker bridge networks are present; filter LAN information to `wlp59s0`, `tailscale0`, and known service ports when documenting the physical fleet.

### `nas`

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
- SSH aliases: `pc`, `winpc`, `semyons-pc`, `10.0.0.15`.
- Linux SSH hostname: `semyon-pc-cachy`.
- Hardware: desktop chassis, model `MS-7C91`.
- VM readiness verified 2026-07-13: AMD Ryzen 5 5600G (6 cores/12 threads, AMD-V) with an integrated Radeon GPU plus the discrete RX 6600. KVM, `/dev/kvm`, and kernel IOMMU validation pass. Installed `qemu-full 11.0.2-3`, `libvirt 12.5.0`, `virt-manager 5.1.0`, `virt-viewer`, OVMF/UEFI firmware, `swtpm`, SPICE tooling, and AUR `looking-glass 2:B7-7`; `libvirtd.service` is enabled/active, the default NAT network is active/autostarted, and `semyon` belongs to `libvirt`. The iGPU is not currently exposed as a display controller, so BIOS iGPU enablement and moving at least one monitor cable to a motherboard video output remain prerequisites for clean RX 6600 passthrough. Linux storage has about 158 GiB free; the existing 931 GiB Windows NVMe partition is mounted at `/mnt/windows-drive`, has about 550 GiB free, and contains a Windows installation. Prefer a separate virtual disk over raw-booting that dual-boot Windows partition unless the additional activation, driver, filesystem, and rollback risks are explicitly accepted.
- OS from SSH: CachyOS, kernel `7.1.8-1-cachyos` (verified 2026-08-12); `ssh pc` lands here as `semyon-pc-cachy` (re-verified 2026-08-23). Windows side answers as `foxsc@10.0.0.15` when booted.
- Access: `ssh pc` or `ssh 10.0.0.15`.
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
