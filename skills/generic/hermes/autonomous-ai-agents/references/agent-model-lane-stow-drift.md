# Agent model-lane instruction drift and stow checks

Use when Semyon says a model-lane/routing rule was already documented, should be a skill, or may have been lost by stow or another device.

## Where to look

1. Search Hermes sessions for the exact phrase and broader terms.
2. Check stow-managed dotfiles first, not just root `~/AGENTS.md`:
   - `~/dotfiles/claude/.claude/AGENTS.md`
   - `~/dotfiles/claude/.claude/CLAUDE.md`
   - `~/dotfiles/claude/.claude/fable-codex-orchestration.md`
   - `~/dotfiles/codex/.codex/AGENTS.md`
   - package READMEs under `~/dotfiles/claude/` and `~/dotfiles/codex/`
3. Check live files and symlink targets:
   - `~/.claude/AGENTS.md`
   - `~/.claude/CLAUDE.md`
   - `~/.claude/fable-codex-orchestration.md`
   - `~/.codex/AGENTS.md`
4. Compare live vs source. Claude may be symlinked while Codex may be a regular file; patch both live and stow source if they drift and the user wants the rule active now.

## Classification rule

Model-lane routing such as “Fable owns SVG cleanup/imagery, Gemini is visual QA, Codex handles bounded mechanical work” is procedural knowledge. Put it in class-level skills and agent instruction docs, not in user-profile memory except for a compact general preference.

## Patch shape

- Keep the root rule short in `AGENTS.md` / `CLAUDE.md`.
- Put detailed orchestration playbooks in linked docs such as `fable-codex-orchestration.md`.
- If Codex should know about a lane but not own the final judgment, phrase it explicitly: Codex can do bounded mechanical edits/search/tests but is not the final taste judge.
- Verify final presence with a grep/search across both live and stow-managed files, then report which files are symlinked and which are not.

## Pitfalls

- Do not conclude a rule is missing after checking only `/home/semyon/AGENTS.md`; the real agent guidance may live under stow packages.
- Do not preserve procedural routing only as memory. Future agents need it in the skill/instruction path they actually load.
- Do not assume stow deployment: verify `readlink -f` and compare live/source content.
