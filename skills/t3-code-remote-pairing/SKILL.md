---
name: t3-code-remote-pairing
description: Generate and verify T3 Code headless remote pairing links for Semyon's server setup, especially the Cloudflare Tunnel at t3.semyon.ie.
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# T3 Code Remote Pairing

Use this when Semyon asks for a T3 Code pairing code/link, asks whether the T3 tunnel is working, wants to pair a client to the persistent headless backend, or wants to inspect how much prompt/context T3 Code forwards to a coding model.

Related reference: `references/prompt-context-audit.md` documents how to compare T3/Codex prompt payloads against Hermes system prompts using local SQLite/log/JSONL state.

Related reference: `references/t3-claudex-cliproxy-integration.md` covers the durable localhost-only T3 → Claude Code shim → CLIProxyAPI pattern, provider-neutral thinking pass-through, T3's Claude-specific `ultrathink`/`ultracode` pitfalls, lane-based model selection, and bounded verification before upstream OAuth usage.

Related reference: `references/t3-memory-balloon-db-hydration.md` covers V8 heap/RSS ballooning from SQLite event/activity bloat, installed-binary-vs-source mismatches, and read-only triage for unbounded snapshot/detail hydration.

Related reference: `references/t3-project-db-dedupe-and-thread-preservation.md` covers read-only diagnosis and safe SQLite repair for duplicated/missing-looking T3 projects: distinguish never-registered folders vs deleted projects vs duplicate `workspace_root` rows, merge thread ownership into one canonical UUID, preserve removed project rows in an audit table, and verify service health.

Related reference: `references/t3-cli-nightly-and-data-preservation.md` covers CLI channel mismatches (`latest` vs `nightly`) and the safe read-only/preservation workflow before restoring apparently missing T3 data.

Related reference: `references/project-registry-missing-projects.md` covers missing T3 projects where folders exist on disk/GitHub but are not first-class `projection_projects` rows, including read-only SQLite probes, lifecycle-event checks, filesystem/Git remote manifest generation, and safe CLI re-add workflow.

Related reference: `references/ai-agent-corpus-inventory-and-export.md` plus `scripts/ai-agent-corpus-inventory.py` cover read-only inventory/export planning for Semyon's local AI-agent training corpus across T3, Codex, Hermes, Claude, opencode, Gemini/Antigravity, Cursor, and Copilot state stores.

Related reference: `references/codex-merge-backup-normalization.md` covers safe `~/.codex-merge-backup` containment checks and no-loss merge strategy: normalize Windows/WSL path variants to `/home/semyon`, stage/validate JSONL merges first, preserve unique backup body events, avoid adding backup `session_meta` headers, and keep rollback copies before replacing live Codex rollout files.

Related reference: `references/pc-blank-slate-and-secure-storage.md` covers PC-only blank-slate resets, preserving old workstation state, and fixing desktop secure-storage pairing errors with a user-level `--password-store=basic` launcher wrapper.

Related reference: `references/project-index-missing-projects.md` covers read-only triage for projects missing from T3 Code, including SQLite projection checks, filesystem-vs-DB root comparison, soft-deleted project detection, and safe `t3 project add` recovery instead of direct DB surgery.

Related reference: `references/mobile-android-ui-icon-inspection.md` covers the Android preview mobile UI/icon path, including thread row Archive/Delete actions, hidden swipe/long-press affordances, and the Tabler/SVG Android icon fallback so missing icons are not misdiagnosed as Nerd Font issues.

Related reference: `references/mobile-upstream-shipping-vs-self-builds.md` covers the distinction between Semyon's cron-built APK mirror and upstream officially shipped mobile artifacts, including how to inspect GitHub releases and EAS workflow config before answering whether mobile must be built from source.

Related reference: `references/mobile-stale-shell-snapshot-replay.md` covers mobile thread lists that stop updating past a point even though the backend has newer threads, including stale shell snapshot replay diagnosis, cold-cache user workaround, and proper stale-cursor code fix.

Related reference: `references/mobile-stale-cursor-snapshot-guard.md` covers the documented snapshot-vs-delta architecture, deleted/archived filtering, a protocol-safe stale-cursor guard, race/sequence caveats, regression tests, and the narrow upstream-PR framing.

Current canonical setup

- Host: `server` / `10.0.0.5`
- T3 Code owner: user systemd unit `t3-code-headless.service`
- Local origin: `http://127.0.0.1:3773`
- Public/LAN hostname: `https://t3.semyon.ie`
- Cloudflare Tunnel stack: `/home/semyon/server-stacks/t3-code`
- Tunnel container: `t3-code-cloudflared`
- LAN split-horizon DNS: Pi-hole dnsmasq include `/etc/dnsmasq.d/99-semyon-lan-overrides.conf` with `address=/t3.semyon.ie/10.0.0.5`

## CLI/package channel discipline

For Semyon's devices, keep the CLI on the same channel as the desktop/nightly app. The npm `latest` dist-tag can lag behind the AUR `t3code-nightly-bin` desktop package and create apparent data/schema mismatch symptoms. When the desktop app is `t3code-nightly-bin`, install/update the CLI with:

```bash
npm --prefix ~/.local install -g t3@nightly
~/.local/bin/t3 --version
npm view t3 dist-tags --json
```

If npm refuses because an older symlink already exists under `~/.local/bin/t3`, inspect it first, then use `--force` only for that scoped user-local install. **Self-referential shims are fatal:** if `~/.local/bin/t3` or `~/.local/bin/node` points back to itself, remove that exact broken shim before reinstalling; `/usr/bin/env node` does not skip the loop even if an interactive shell appears to find the real nvm Node later in PATH. When a reinstall prints `install scripts blocked` for `node-pty`, install the scoped package with `--allow-scripts=node-pty,msgpackr-extract` and verify the native dependency explicitly before restarting the service:

```bash
npm --prefix ~/.local install -g --allow-scripts=node-pty,msgpackr-extract t3@nightly
node -e 'require("/home/semyon/.local/lib/node_modules/t3/node_modules/node-pty"); console.log("node-pty=loadable")'
```

Do not use `--ignore-scripts` for the headless backend: `t3 --version` may work while `t3 serve` fails on the missing `node-pty` binary.

### Server update-function guard

Semyon's server `update()` function may update ordinary npm CLIs from the active nvm prefix and create convenience links in `~/.local/bin`. **Exclude `t3` from that generic link loop.** The systemd service intentionally invokes `/home/semyon/.local/bin/t3`; if an update replaces it with a link into nvm's global `t3`, the global package can lack `node-pty`'s native `pty.node` and T3 will crash at startup. Update T3 separately and defensively:

```bash
rm -f ~/.local/bin/t3
npm --prefix ~/.local install -g --allow-scripts=node-pty,msgpackr-extract t3@nightly
readlink -f ~/.local/bin/t3
node -e 'require("/home/semyon/.local/lib/node_modules/t3/node_modules/node-pty"); console.log("node-pty=loadable")'
```

The resolved executable must be `/home/semyon/.local/lib/node_modules/t3/dist/bin.mjs`, not an nvm-global path. Restart the service and run the LAN/public probes below after any such update.

### nvm and local-bin recovery pitfall

Do **not** export `NPM_CONFIG_PREFIX=$HOME/.local` or configure `prefix=${HOME}/.local` in `.npmrc` on a host using nvm. It makes `nvm use` abort because nvm must control the prefix. When repairing a mixed nvm/local-bin setup, remove that override from every applicable shell startup file (`.bashrc`, `.zshrc`, `.profile`, `.zprofile`) and `.npmrc`; then test in a fresh interactive shell that `NPM_CONFIG_PREFIX` is unset and `npm`, `npx`, and provider CLIs resolve under the active nvm version.

If several `~/.local/bin` executables suddenly fail with `Too many levels of symbolic links` / `spawn ELOOP`, audit the whole directory rather than fixing only the first command. A self-referential shim shadows a valid nvm-installed CLI. Remove only shims proven to loop, then verify each required surface (`npm`, `npx`, `claude`, `codex`, `t3`) in a fresh login shell. Do not reinstall a provider merely because its local shim is broken: check the nvm global prefix first.

## Generate a pairing link

Run from the server as Semyon:

```bash
/home/semyon/.local/bin/t3 auth pairing create \
  --ttl 1h \
  --label t3-cf-tunnel \
  --base-url https://t3.semyon.ie \
  --json
```

Return the `pairUrl`, the short `credential`, and the expiry time. The credential is ephemeral but still sensitive enough to avoid logging unnecessarily.

Example output fields:

```json
{
  "credential": "XXXXXXXXXXXX",
  "expiresAt": "...",
  "pairUrl": "https://t3.semyon.ie/pair#token=XXXXXXXXXXXX"
}
```

## Verify before/after pairing

```bash
systemctl --user show t3-code-headless.service -p ActiveState -p SubState -p MainPID -p NRestarts --no-pager
curl -fsS -I --max-time 5 http://127.0.0.1:3773/
docker ps --filter name=t3-code-cloudflared --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'
cloudflared tunnel info t3-code
curl -fsS -I --max-time 20 --resolve t3.semyon.ie:443:104.21.44.64 https://t3.semyon.ie/
dig +short @10.0.0.5 t3.semyon.ie A
curl -kIsS --max-time 8 --resolve t3.semyon.ie:443:10.0.0.5 https://t3.semyon.ie/
```

Healthy signs:

- `t3-code-headless.service` is `active/running`, ideally `NRestarts=0` since the last intentional restart.
- Local origin returns `HTTP 200`.
- `t3-code-cloudflared` is up.
- `cloudflared tunnel info t3-code` shows an active connector and Cloudflare edge locations.
- Public `https://t3.semyon.ie/` returns `HTTP/2 200`.
- Pi-hole returns `10.0.0.5` for `t3.semyon.ie`; LAN HTTPS returns `HTTP/2 200` through Nginx **and its certificate validates**. Do not treat `curl -k` as a health check: the current LAN Nginx vhost uses a Cloudflare Origin CA certificate, which browsers/Electron clients correctly reject. Before enabling or diagnosing LAN split-horizon access, require a normal client-side `curl -fsSI https://t3.semyon.ie/` and `openssl s_client -verify_return_error` to succeed. For simultaneous LAN-direct and Cloudflare-Tunnel access, install a publicly trusted certificate (normally ACME DNS-01 for `semyon.ie`) on Nginx; never add Cloudflare Origin CA to workstation trust stores as a workaround.

## Clean `tool.updated` activity spam from the live DB

Use this when T3 Code starts disconnecting or the state DB explodes because every streaming `item.updated`/`tool.updated` tick is projected into append-only thread activities. The live DB path is currently `/home/semyon/.t3/userdata/state.sqlite`.

If the service is currently crash-looping from V8 heap OOM, a reversible emergency stabilizer is:

```bash
systemctl --user set-environment NODE_OPTIONS='--max-old-space-size=8192'
systemctl --user restart t3-code-headless.service
```

This only lasts until the user systemd manager is restarted unless made persistent in the unit/wrapper. Verify with `/proc/<node-pid>/environ`, RSS growth, and public `https://t3.semyon.ie/` HTTP 200. It buys time; it is not the real fix.

Prereqs:

- Confirm the installed bundle has the writer fix first. Semyon's user-local install path is usually `/home/semyon/.local/lib/node_modules/t3/dist/bin.mjs` (not only the nvm global path). The `case "item.updated"` branch should `return [];`. If the current `t3@nightly` still emits `kind: "tool.updated"`, cleanup alone will re-accumulate spam; report that and avoid pretending the DB cleanup is durable.
- Stop the service before mutating SQLite: `systemctl --user stop t3-code-headless.service`.
- Make a timestamped backup before deletes.

Python cleanup pattern, because `sqlite3` CLI may not be installed:

```bash
python3 - <<'PY'
import sqlite3, shutil, time
from pathlib import Path
DB = Path('/home/semyon/.t3/userdata/state.sqlite')
backup = DB.with_name(DB.name + '.backup-before-tool-updated-clean-' + time.strftime('%Y%m%d-%H%M%S'))
shutil.copy2(DB, backup)
con = sqlite3.connect(DB, timeout=60)
cur = con.cursor()
cur.execute('PRAGMA busy_timeout=60000')
cur.execute('PRAGMA foreign_keys=OFF')
cur.execute('PRAGMA journal_mode=DELETE')
cur.execute("DELETE FROM projection_thread_activities WHERE kind='tool.updated'")
cur.execute("""
DELETE FROM orchestration_events
WHERE event_type='thread.activity-appended'
  AND json_extract(payload_json,'$.activity.kind')='tool.updated'
""")
con.commit()
print('projection remaining', cur.execute("SELECT count(*) FROM projection_thread_activities WHERE kind='tool.updated'").fetchone()[0])
print('event remaining', cur.execute("SELECT count(*) FROM orchestration_events WHERE event_type='thread.activity-appended' AND json_extract(payload_json,'$.activity.kind')='tool.updated'").fetchone()[0])
print('integrity', cur.execute('PRAGMA integrity_check').fetchone()[0])
cur.execute('VACUUM')
con.close()
print('backup', backup)
PY
```

Then restart and verify counts stay zero while normal `tool.started`/`tool.completed` still appear:

```bash
systemctl --user start t3-code-headless.service
curl -fsS http://127.0.0.1:3773/.well-known/t3/environment
curl -fsS -I https://t3.semyon.ie/
```

## Workstation/Desktop T3 recovery

This skill is primarily for the persistent server headless backend, but Semyon may also ask for T3/T3 Code to be restored on a workstation (`pc`, CachyOS/Arch).

When he says “actual real install” or “latest”, distinguish the surfaces:

- **CLI package**: npm package `t3`, installed user-locally where possible:

  ```bash
  npm --prefix ~/.local install -g t3@latest
  ~/.local/bin/t3 --version
  ```

- **Desktop app**: Arch/AUR package such as `t3code-nightly-bin`, installed/updated with the system package/AUR helper:

  ```bash
  paru --skipreview --noconfirm -S --needed t3code-nightly-bin
  pacman -Q t3code-nightly-bin
  ```

- **App launcher/Vicinae entry**: verify the `.desktop` `Exec=` path resolves. If secure storage is healthy and no launcher flags are needed, a simple user-local symlink can be enough:

  ```bash
  ln -sf /usr/bin/t3code-nightly ~/.local/bin/t3code-nightly
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
  systemctl --user restart vicinae.service
  sleep 2
  vicinae ping
  ```

- **Hyprland hotkey in dotfiles**: Semyon expects `Super+C` on the PC and laptop overlays to launch the T3 Code nightly desktop app, not Claude Code in a terminal. In `/home/semyon/dotfiles`, patch the host-specific overlays rather than the shared default when changing this binding, because `hyprland/.config/hypr/hyprland.conf` sources `~/.config/hypr/userprefs.conf` last and host overlays override the shared `$mainMod, C` editor binding:

  ```conf
  # pc/.config/hypr/userprefs.conf and laptop/.config/hypr/userprefs.conf
  unbind = SUPER, C
  bind = SUPER, C, exec, /home/semyon/.local/bin/t3code-nightly
  ```

- **PC-only blank slate**: when Semyon explicitly prefers a blank workstation state, do not keep trying to restore/copy server data. Move `~/.t3` and `~/.config/t3code` into `~/t3-restore-backups/`, relaunch the desktop app, and verify the SQLite projection tables are empty. See `references/pc-blank-slate-and-secure-storage.md`.

- **Desktop secure storage unavailable**: if pairing/connection registration fails because the local connection catalog cannot be saved, inspect the working Chromium/Electron password store first and clone it. On Semyon's PC, `gnome-keyring` owns `org.freedesktop.secrets` and Helium uses `--password-store=gnome-libsecret`, so T3 should use `--password-store=gnome-libsecret`; use `basic` only as a fallback when no real secret service is healthy. Prefer a user-level `~/.local/bin/t3code-nightly` wrapper plus `~/.local/share/applications/t3code-nightly.desktop` override; remove any existing symlink wrapper first and avoid piped `sudo -S` edits to packaged files. See `references/pc-blank-slate-and-secure-storage.md`.

## T3 Code Android preview build watcher

Cron job `cb444c2a287d` (`T3 Code Android version build watcher`) runs script-only/no-agent wrapper `~/.hermes/scripts/t3code-mobile-watch.sh`. It watches the live mobile development branch (`T3_WATCH_SOURCE=mobile-branch`, default `T3_WATCH_BRANCH=main`), validating that `apps/mobile/package.json` still identifies `@t3tools/mobile` before building. Release tags are deliberately refused: they can lag the Android development line and are not a safe mobile-artifact source. The script will reconcile to the PR #3514 base/default/remote-HEAD branch only if the configured mobile branch disappears.

When Semyon asks whether mobile is "being served built" or whether he still needs to build from source, first clarify the surface mentally: the fileshare APK endpoint is Semyon's self-built cron artifact, not proof that upstream officially ships public mobile builds. Upstream releases/nightlies can ship desktop binaries while mobile remains early-alpha/internal EAS/source-build territory. Verify GitHub release assets and mobile EAS workflows before answering; see `references/mobile-upstream-shipping-vs-self-builds.md`.

Current durable paths:

- Worktree/cache: `/home/semyon/t3code-mobile-work/t3code` — intentionally not `/tmp`, because reboot/tmp cleanup breaks incremental builds.
- Build logs/artifacts: `/home/semyon/t3code-mobile-builds/`
- State: `/home/semyon/.hermes/t3code-mobile-watch/last_success_sha`
- JDK: `/home/semyon/android-build-tools/jdk-21`
- Android SDK: `/home/semyon/android-sdk`
- Canonical public APK: `/home/semyon/server-stacks/fileshare/erugo-storage/app/public/apk/t3-code-preview.apk`
- Download URL: `https://fileshare.semyon.ie/t3-apk.php`, which serves that one canonical current APK.

The script now self-heals common post-reboot/missing-toolchain cases when there is a new commit to build: it bootstraps Temurin JDK 21 and Android command-line tools/SDK components into the durable paths above. It intentionally checks the remote SHA and exits silently before bootstrap when there is no new commit, so no-agent cron stays quiet while healthy. The default whole-build bound is 39 minutes (with a 2150-second Gradle step cap). Expo/RN 0.85/SDK 56 arm64 builds can need the extra time for Metro, Android resource merging, dexing, signing, and packaging; this retains a one-minute margin below the 40-minute cron limit for publication, state writes, cleanup, and reporting. The watcher also hard-resets and `git clean -fd`s its dedicated worktree before each build (preserving ignored caches) so stale untracked source cannot enter a published APK. It runs Expo prebuild incrementally (without `--clean`) so the ignored generated Android tree and Gradle task outputs survive a timeout; prebuild still reconciles the freshly checked-out app configuration before every build. It writes `reactNativeArchitectures=arm64-v8a` into the generated Gradle properties alongside the CLI architecture selector.

After a successful publish it retains exactly one canonical APK at the endpoint path and five build logs by default. It deletes commit-stamped/intermediate APK copies, preserves `node_modules`, pnpm cache, `~/.gradle`, Android SDK/JDK, and removes heavyweight regenerated outputs such as `apps/mobile/android/app/build` and native module `android/build` dirs. Override log retention only with `T3_WATCH_KEEP_BUILD_LOGS` if needed.

If it alerts after a reboot or toolchain failure, check these first and rerun the script manually before declaring it unrecoverable:

```bash
bash -n ~/.hermes/scripts/t3code-mobile-watch.sh
/home/semyon/android-build-tools/jdk-21/bin/java -version
/home/semyon/android-sdk/cmdline-tools/latest/bin/sdkmanager --list_installed
cat ~/.hermes/t3code-mobile-watch/last_success_sha
git ls-remote https://github.com/pingdotgg/t3code.git refs/heads/main
tail -120 /home/semyon/t3code-mobile-builds/t3code-mobile-build-*.log
~/.hermes/scripts/t3code-mobile-watch.sh
```

Known failure signatures:

- `ERR_PNPM_ABORTED_REMOVE_MODULES_DIR_NO_TTY`: script must export `CI=true` and `COREPACK_ENABLE_DOWNLOAD_PROMPT=0` before `pnpm install`.
- `JAVA_HOME is set to an invalid directory: /tmp/android-build-tools/jdk-21`: old tmp-based toolchain was wiped; use the durable `/home/semyon/android-build-tools` and `/home/semyon/android-sdk` paths.
- URL `Content-Length` or SHA mismatch after a successful build: publish to both `public-apk/t3-code-preview.apk` and `erugo-storage/app/public/apk/t3-code-preview.apk`; the PHP download endpoint may read the latter.

Verification after a fix:

```bash
~/.hermes/scripts/t3code-mobile-watch.sh
sha256sum /home/semyon/t3code-mobile-builds/t3-code-preview-arm64-android-<short>.apk \
  /home/semyon/server-stacks/fileshare/public-apk/t3-code-preview.apk \
  /home/semyon/server-stacks/fileshare/erugo-storage/app/public/apk/t3-code-preview.apk
curl -kIsS --max-time 10 https://fileshare.semyon.ie/t3-apk.php | head
```

## LAN direct-access binding

The normal configuration is loopback-only with Cloudflare/T3 HTTPS as the remote surface. **If Semyon explicitly requests direct LAN access**, bind the backend to all interfaces and update both sources of truth — the systemd environment *and* the launcher script. The launcher passes an explicit CLI `--host` and therefore overrides the unit environment if they disagree.

1. Update `~/.config/systemd/user/t3-code-headless.service` (stowed from `~/dotfiles/server/.config/systemd/user/t3-code-headless.service`):
   ```ini
   Environment=T3CODE_HOST=0.0.0.0
   ```
2. Update `~/bin/t3-headless-run` (stowed from `~/dotfiles/server/bin/t3-headless-run`) consistently:
   ```bash
   export T3CODE_HOST=0.0.0.0
   # ...
   /home/semyon/.local/bin/t3 serve --host 0.0.0.0 --port 3773 --no-browser /home/semyon
   ```
3. Apply and verify:
   ```bash
   systemctl --user daemon-reload
   systemctl --user restart t3-code-headless.service
   ss -ltnp '( sport = :3773 )'
   curl -fsS --max-time 8 http://10.0.0.5:3773/.well-known/t3/environment
   curl -fsS -I --max-time 15 https://t3.semyon.ie/
   ```

Expect `ss` to show `0.0.0.0:3773`; the exact LAN environment endpoint should return JSON. Immediately after a restart the service can still be warming up, so retry the HTTP probe once before diagnosing a networking failure.

**Effective-unit check:** before declaring the bind fixed, run `systemctl --user cat t3-code-headless.service` as well as inspecting the primary unit and launcher. A drop-in under `~/.config/systemd/user/t3-code-headless.service.d/` can override `Environment=T3CODE_HOST` and reset `ExecStart` with a hard-coded `--host 127.0.0.1`, silently defeating both intended sources of truth. If Semyon has requested LAN binding, remove or update that conflicting drop-in, then `daemon-reload`, restart, and verify `0.0.0.0:3773` plus a real `http://10.0.0.5:3773/.well-known/t3/environment` HTTP 200 probe.

## T3 provider routing through a local CLIProxyAPI

When Semyon wants T3 Code to use non-Claude models through a `claudex` executable, keep the proxy bound to loopback: T3 and the proxy normally run on the same server, so a LAN/public listener is unnecessary. Treat this as a provider-profile feature, not a global `ANTHROPIC_BASE_URL` override: native `claude` remains native, while only the dedicated T3 instance uses the wrapper.

Before implementation, independently inspect the T3 Claude-driver source, the wrapper, and the proxy configuration. Compare the lightweight alias/lane option against a dedicated profile; when the user wants a true no-default reasoning selector, prefer a maintained `cliproxy` profile in T3 source over model×level aliases. Never use generated cache files or edit installed `dist/bin.mjs` as the durable implementation.

For the exact provider-neutral reasoning rules, wrapper/T3 probe requirement, billing boundary, and test matrix, see `references/t3-claudex-cliproxy-provider-profile.md`.

## Pitfalls

- Do not start a second T3 backend manually unless intentionally debugging. The persistent owner is systemd.
- When OpenCode is installed through its official bootstrap, its executable may be `~/.opencode/bin/opencode` (with `~/.local/bin/opencode` only a convenience link), not `/usr/bin/opencode`. T3 stores the provider path in `~/.t3/userdata/settings.json` at `providers.opencode.binaryPath`; a stale `/usr/bin/opencode` setting makes the provider disappear even though `opencode models` works interactively. Point it to the real executable, restart `t3-code-headless.service`, and verify the OpenCode inventory exposes the expected `opencode/*` and `moonshotai/kimi-k3` slugs.
- Changing only `T3CODE_HOST` in the systemd unit is insufficient while `t3-headless-run` hard-codes `--host 127.0.0.1`; inspect the actual `MainPID` command line and launcher whenever the live listener disagrees with unit configuration.
- Do not assume missing threads/settings mean deletion. First inventory `~/.t3`, `~/.config/t3code`, and `~/.t3/userdata/state.sqlite`; run SQLite `PRAGMA integrity_check` read-only and count `projection_threads`, `projection_thread_messages`, and related tables before restoring anything.
- Before any restore, make a non-destructive preservation copy: use SQLite backup API for `~/.t3/userdata/state.sqlite` plus copy key JSON files (`settings.json`, `keybindings.json`, `saved-environments.json`, `connection-catalog.json`) and lightweight `~/.config/t3code` metadata. Avoid Btrfs/snapper rollback until live data is proven semantically corrupted.
- T3 is alpha; pairing/session oddities are normal. Generate a fresh token rather than reusing stale ones.
- For HTTPS web clients, use the HTTPS `base-url`; plain `http://LAN:3773` can fail from browser mixed-content rules.
- Do not paste long-lived secrets from `~/.t3`; pairing tokens are one-time/temporary, but still time-limited access credentials.
