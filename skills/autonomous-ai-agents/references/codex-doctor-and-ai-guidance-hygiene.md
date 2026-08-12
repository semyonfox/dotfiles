# Codex Doctor repair and AI-guidance hygiene

Use when Codex Doctor reports an install/update-path mismatch, stale rollout references, or when refreshing Claude/Codex global routing docs.

## Safe repair sequence

1. Run `codex doctor --no-color` and record the running package root, the npm global package root, state-integrity result, and warnings separately.
2. Confirm wrapper topology with `stat -c '%N' ~/.local/bin/codex` and inspect `npm prefix -g` / `npm root -g` from the shell that actually launches Codex.
3. Align the executable with the configured global npm root instead of changing broad Node/npm prefix configuration. If an old wrapper/symlink blocks installation, preserve it in `~/.codex/repair-backups/` first, then reinstall the current Codex version through that npm root.
4. Re-run Doctor. Do not hand-edit Codex SQLite databases to silence historical missing-rollout warnings when Doctor says the databases are healthy.
5. Empty session JSONL files are unusable artifacts. Archive, do not destroy, them under `~/.codex/repair-backups/<timestamp>/`, then re-run Doctor. Remaining stale references may be historical migration metadata with no supported repair command.
6. For a model-default change, place `model` and `model_reasoning_effort` at TOML top level, before any `[projects.*]` table. Settings inserted after a project table belong to that table and will not become global. Verify with both `tomllib` and Doctor's reported effective model.

## Guidance refactor pattern

- Preserve the Stow source and confirm live/source identity after editing.
- Keep one concise shared Claude policy as the model-routing and stop-boundary source of truth; let the local-context AGENTS file point to it rather than duplicating it.
- Keep the detailed Fable/Codex task-card protocol in a linked playbook.
- Keep Codex's own AGENTS compact but self-sufficient because it does not load Claude guidance.
- Require a task card to name a phase, named verification, `stop after` condition, and explicit non-goals.
- State the Gemini/Antigravity role consistently: Gemini is the eyes, reporting concrete visual observations; lead models make taste, architecture, product, and implementation decisions.

## Verification

```bash
codex doctor --summary --no-color
python3 - <<'PY'
import tomllib
with open('~/.codex/config.toml'.replace('~', __import__('os').path.expanduser('~')), 'rb') as f:
    c = tomllib.load(f)
print(c.get('model'), c.get('model_reasoning_effort'))
PY
cd ~/dotfiles && stow -n --no-folding claude
git diff --check -- claude codex
```

Do not force `stow codex` if the existing local Codex skills/config are regular files and the dry run reports conflicts. Keep the targeted source and live global `AGENTS.md` synchronized until a deliberate Stow migration is planned.
