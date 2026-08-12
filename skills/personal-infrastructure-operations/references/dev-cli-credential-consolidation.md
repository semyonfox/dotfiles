# Dev CLI credential consolidation from NAS/device dumps

Use when Semyon asks to recover, clean up, or centralize developer CLI credentials from NAS backups/device dumps into the current server/home.

## Scope

Target normal CLI credential/config homes rather than doing an unbounded forensic grep first:

- AWS: `~/.aws/config`, `~/.aws/credentials`
- Cloudflare/Wrangler: `~/.wrangler/config/default.toml`, `~/.config/.wrangler/config/default.toml`
- cloudflared: `~/.cloudflared/cert.pem`, `~/.cloudflared/*.json`, tunnel config YAML
- GitHub CLI: `~/.config/gh/hosts.yml`, `~/.config/gh/config.yml`
- Docker: `~/.docker/config.json`
- rclone: `~/.config/rclone/rclone.conf`
- npm/PyPI: `~/.npmrc`, `~/.pypirc`
- Doppler/1Password/other dev CLIs: normal dot/config dirs only when found
- Google/GAM/Gemini/Firebase: keep separate from the above; do not mix consumer OAuth, Workspace/GAM, Gemini OAuth, and service-account keys.

## Workflow

1. Load this skill and start with a targeted inventory of current server locations plus NAS/device dump roots under `/mnt/media/users/semyon/device_dumps`.
2. Produce a redacted inventory artifact (`*.json` and/or `*.md`) that lists type, path, mtime, size, hash, safe account/project/profile metadata, and duplicate count. Never print token/key values.
3. Choose canonical destinations by class. Prefer newest NAS source per canonical destination unless the current server copy is the only candidate. For cloudflared tunnel JSONs, preserve all unique tunnel credential files by basename/hash.
4. Create a timestamped local backup bundle before mutation:
   `~/.credentials-cleanup-backups/<class>-YYYYMMDD-HHMMSS/`
   with `current-server/`, `nas-sources/`, `manifest.json`, `delete-sources.txt`, and `deleted.json`; chmod it `0700`.
5. Copy source files into canonical homes with plain `cp`/`shutil.copy2`, not `cp -a`, when copying from NAS/NFS. Preserving NAS ownership/mode can fail and is not desired. Then set owner `semyon:semyon`, dirs `0700`, files `0600`.
6. Verify destination SHA256 matches the source before deleting anything.
7. Delete only exact source files from the manifest, never broad directories or whole backups. If a post-delete inventory finds older duplicate credential files, back those exact files into the same local backup bundle, delete them, and re-run the targeted inventory.
8. Verify final state: destination stats, deleted-source absence, backup bundle perms. Run safe auth/status probes only when binaries are installed and the probe will not reveal secrets.

## Reporting

Report concise state:

- backup bundle path
- migrated canonical locations
- count/classes of NAS files deleted
- any CLIs currently missing as binaries (without treating missing binaries as failure)
- explicit caveat: targeted normal dev-CLI credential cleanup is not a full byte-level secret scan of the whole NAS

## Pitfalls

- Do not centralize everything into one secrets junk drawer. Keep tool-native locations for CLIs and a separate `~/secrets/...` or vault path for service-account keys.
- Do not use Gemini/cloud-platform OAuth tokens as Gmail tokens; scopes differ.
- Do not leave group ownership from NAS (`users`) on copied secrets; normalize to `semyon:semyon`.
- Do not print raw tokens, refresh tokens, private keys, app passwords, service-account JSON bodies, or Docker auth blobs.
- Do not overclaim: after targeted cleanup, say “the normal discovered credential locations are clean,” not “the entire NAS contains no secrets.”