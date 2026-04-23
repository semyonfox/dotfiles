# Claude Code No Flicker Alias Design

## Goal

Add `CLAUDE_CODE_NO_FLICKER=1` to the existing `cc` alias for both bash and zsh so the no-flicker behavior is enabled only when launching Claude Code through `cc`.

## Current State

- `home/.bash_aliases` defines `cc` as `LS_DEMO=1 claude --dangerously-skip-permissions`
- `home/.zsh_aliases` defines `cc` as `LS_DEMO=1 claude --dangerously-skip-permissions`
- Bash and zsh alias files are intentionally kept in parallel in this dotfiles repo
- The repo is managed through GNU Stow, so changes must be made under `home/` rather than directly in `$HOME`

## Recommended Approach

Update the existing `cc` alias line in both files by prefixing the command with `CLAUDE_CODE_NO_FLICKER=1`.

Target alias form:

- `alias cc='CLAUDE_CODE_NO_FLICKER=1 LS_DEMO=1 claude --dangerously-skip-permissions'`

This keeps the environment variable scoped to the alias invocation, preserves the current `LS_DEMO=1` behavior, and avoids changing shell startup behavior for any other Claude Code command.

## Alternatives Considered

### Export Globally

Add `export CLAUDE_CODE_NO_FLICKER=1` in `.bashrc` and `.zshrc`.

This was rejected because it would affect all Claude Code invocations, not just `cc`.

### Replace Alias With Function

Replace `cc` with a shell function that sets environment variables before running `claude`.

This was rejected because the current alias already expresses the required behavior and a function would add unnecessary complexity.

## Risks

- low risk of drift if only one shell file is updated
- low risk of overwriting nearby unrelated edits in these files if the change is not tightly scoped

## Verification Plan

After implementation, verify with:

- reading back the `cc` alias line from `home/.bash_aliases`
- reading back the `cc` alias line from `home/.zsh_aliases`
- optionally running `stow home` when the user is ready to deploy the dotfiles

## Non-Goals

- no change to other aliases such as `cx` or `oc`
- no global shell export for `CLAUDE_CODE_NO_FLICKER`
- no change to the `claude` command outside the `cc` alias
