# Fable/Codex orchestration linked playbook

Use when Semyon asks to encode a Claude/Fable workflow where Fable should orchestrate and delegate implementation to Codex GPT-5.5 rather than doing the mechanical work itself.

## Durable pattern

- Prefer updating the loaded class-level Claude guidance (`CLAUDE.md` and/or `AGENTS.md`) plus a small linked support file, not dumping a long model-routing block inline.
- In stow-managed setups, preserve both source and live files:
  - stow source: `~/dotfiles/claude/.claude/...`
  - live files: `~/.claude/...`
  - check whether each live file is a symlink; if not, patch both live and source or restore the intended symlink only when safe.
- Add a compact inline pointer such as:

```md
- detailed playbook: @~/.claude/fable-codex-orchestration.md
```

- The linked file should define roles clearly:
  - Fable/Claude owns planning, architecture, task decomposition, taste/security/product judgment, and final review.
  - Codex owns bounded implementation, mechanical refactors, codebase search, test generation, and verification runs.
  - Codex output is a patch candidate; Fable must inspect diffs and rerun checks before accepting it.
- Keep Codex prompts as compact task cards: repo path, goal, context, constraints, required verification, and expected return format.
- Make risky or parallel Codex work use isolated git worktrees and file-ownership boundaries.

## Codex command shape

For GPT-5.5 worker runs, prefer a command like:

```bash
codex exec \
  --cd "$REPO" \
  -m gpt-5.5 \
  -c model_reasoning_effort='"high"' \
  -s workspace-write \
  "$PROMPT"
```

Treat `model_reasoning_effort="high"` as a CLI-safe stand-in for "max thinking" unless the local `codex exec --help` or config clearly exposes a stronger accepted value. Do not invent unsupported flags.

## Verification

- Check `command -v codex && codex --version` and `codex login status` before claiming the route is usable.
- Check `command -v claude && claude --version` and Claude auth/model settings when the task concerns Claude/Fable routing.
- Verify the edited live and source files match or have the intended symlink relationship.
- If `stow` is unavailable, do not encode that as durable failure; report that live/source were manually synced and remind Semyon to run `stow claude` once available.
