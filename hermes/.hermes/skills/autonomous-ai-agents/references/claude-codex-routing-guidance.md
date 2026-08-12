# Claude/Codex routing guidance capture

Use when Semyon asks to "do this" from a post or idea about Claude using Codex/Fable-style fallbacks to reduce token pressure or rate-limit burn.

## Durable pattern

1. Treat the ask as an agent-guidance update, not a generic explanation, when the user asks what can be done and the artifact is clearly a workflow tip.
2. Inspect the live global Claude guidance files and the stow-managed source. On Semyon's machines this often means checking both `~/.claude/AGENTS.md` / `~/.claude/CLAUDE.md` and `~/dotfiles/claude/.claude/...` equivalents rather than editing only the live symlink target.
3. If the intent is “Fable 5 as the master brain,” also inspect `~/.claude/settings.json`: set `model` to the stable alias `fable` (or an explicitly requested full slug) and choose an effort level appropriate to the role, usually `medium` for a default lead model. Keep this separate from the stow-managed guidance files because Claude settings may contain noisy/local permission state.
4. Add a compact class-level section such as `## model routing` that tells Claude:
   - Fable 5 (`fable` / `claude-fable-5`) is the lead/master brain for planning, architecture, debugging strategy, task decomposition, and final review;
   - Codex GPT-5.5 is a worker for bounded implementation, mechanical refactors, test generation, and codebase searches that would burn Fable tokens;
   - for Codex max-thinking worker tasks, use `codex exec -m gpt-5.5 -c model_reasoning_effort='"xhigh"' ...` when the local CLI accepts it; a live probe on Semyon's setup reported `reasoning effort: xhigh`;
   - Codex must not own broad product judgment, security-sensitive decisions, or final approval;
   - verify Codex exists and is authenticated before relying on it;
   - run Codex from the target repo/worktree, not `$HOME`;
   - keep Codex prompts narrow and require verification;
   - inspect Codex diffs and rerun relevant checks before claiming success;
   - use worktrees for risky or parallel tasks, and never let two agents write the same file;
   - when Fable limits are tight, shrink scope first and fall back only for continuation, not unreviewed risky final approval.
5. Verify installed agent CLIs, auth, and Fable availability signals with native commands where available (`claude auth status`, `codex login status`, versions, `additionalModelOptionsCache`, or a tiny `claude --model fable -p ...` probe if quota permits). Report configured capability separately from current quota/session-limit blockers.
6. If stow is available, dry-run or deploy the relevant package. If system package installation is unavailable but the user wants stow now, a safe fallback is to extract the distro `stow` package under `~/.local/opt/stow`, wrap `~/.local/bin/stow` with `PERL5LIB` pointing at the extracted `usr/share/perl5`, then run `stow -n -v <package>` and only replace live files with symlinks after `cmp` confirms the live file matches the stow source.

## Pitfalls

- Do not answer with a theory essay if the user likely wants the workflow encoded into the agent instructions.
- Do not edit only `~/.claude/CLAUDE.md` when dotfiles are stow-managed; preserve the source-of-truth package too.
- Do not trust a symlink assumption without checking `readlink -f` or equivalent.
- Do not let Codex output become trusted truth; Claude/Hermes remains the reviewer/verifier.
