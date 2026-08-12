# OpenClaw decommissioning after Hermes migration

Use this when Semyon says the old OpenClaw setup can be removed after a successful migration.

## What to remove

Remove only the old source/staging/runtime leftovers, for example:

- `~/.openclaw.pre-migration/`
- `~/.hermes/migration/openclaw/` once its useful notes have been condensed into Hermes skills/references
- stale OpenClaw-specific config backups such as `~/.hermes/config.yaml.bak-openclaw-*`
- stale user systemd backup/service files such as `~/.config/systemd/user/openclaw-gateway.service.bak`

## What to keep

Keep the Hermes-side migrated material:

- `~/.hermes/imported-openclaw-workspace/` raw compact archive of the useful workspace/persona source
- `~/.hermes/skills/productivity/openclaw-agent-team/`
- a small backup/audit snapshot under `~/.hermes/backups/` if present
- Hermes source-tree OpenClaw migration tests/optional skill under `~/.hermes/hermes-agent/`; those belong to Hermes itself, not the old user runtime

## Verification pattern

After cleanup, verify both halves:

1. Old source/staging paths are gone.
2. Hermes config still contains `agent.personalities` for `camille`, `theo`, `chuck`, `r2d2`, and `eidhne`.
3. The `openclaw-agent-team` skill still exists.
4. The imported workspace archive still exists.

Use `find`/path checks rather than assuming the removal worked. If the remaining matches are only Hermes-side archive/skills/backups and Hermes source tests, the decommission is clean.
