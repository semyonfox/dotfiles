# Claude print-mode read-only reviews

Use this for an asynchronous Fable/Claude Code second-opinion review without permitting repository mutation.

## Invocation

`--allowed-tools` accepts a variable-length list. When a positional prompt follows it, insert `--` before the prompt or Claude may parse the prompt as another tool name and report that no input was supplied.

```bash
claude -p --model fable --effort medium --max-turns 12 \
  --allowed-tools 'Read,Glob,Grep,Bash(git *),Bash(gh *)' -- \
  'Review PR #123 read-only. Do not edit, commit, push, comment, merge, fetch, rebase, checkout, reset, restore, stash, or alter files. Use only non-mutating git and gh commands. Return a compact MERGE/READY, HOLD, or NEEDS-CHANGES verdict with concrete evidence.'
```

## Guardrails

- Use a repo-specific working directory.
- Treat the Fable verdict as advisory; independently verify current PR state, checks, mergeability, and working-copy status.
- For multiple repositories, run separate background commands and write each output to a distinct `/tmp/fable-<repo>-review-<date>.md` file.
- If a broad review exhausts its turn budget, narrow the retry to one PR or one local patch rather than treating it as a completed review.
- Re-check `git status` after the review to prove the read-only boundary held.
