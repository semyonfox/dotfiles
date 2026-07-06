# fable/codex orchestration playbook

use this when Claude Code is running on Fable and the work can be split into bounded implementation/search/test tasks. the goal is not for Fable to type all the code. the goal is for Fable to understand the problem, make the decisions, feed Codex the right context, and verify the result inside the short Fable window.

keep Fable reasoning at `high` by default. avoid `x-high`, `max`, and `ultra code` for Fable unless there is a specific reason.

## model scores

rankings are 1-10 and higher is better. `cost` means cost-efficiency/availability for Semyon's actual usage, not public list price; OpenAI may rank high because it is near-free for this account.

| model | cost | intelligence | taste |
|---|---:|---:|---:|
| gpt-5.5 | 9 | 8 | 5 |
| sonnet-5 | 5 | 5 | 7 |
| opus-4.8 | 4 | 7 | 8 |
| fable-5 | 2 | 9 | 9 |

use `cost` only as a tiebreaker after intelligence and taste needs are met.

## roles

- **Fable/Claude owns orchestration:** goal clarification, repo reconnaissance, architecture choices, constraints, task decomposition, security/product judgment, and final review.
- **Codex owns bounded execution:** implementation, mechanical refactors, codebase search, test generation, migration edits, and running verification commands.
- **other models can help investigate:** use cheaper or more plentiful models for bulk reading, summaries, and independent review, then verify important claims yourself.
- **Fable must not rubber-stamp Codex:** Codex output is a patch candidate. inspect diffs, rerun checks, and fix or revert anything suspect.
- **do not delegate taste-critical final calls:** UI/UX direction, copy, API design, auth/security behavior, data deletion, and public-facing decisions stay with Fable unless the user explicitly asks otherwise.

## default Codex command

from the target repo or an isolated worktree, prefer GPT-5.5 with the highest stable reasoning effort exposed by the CLI:

```bash
codex exec \
  --cd "$REPO" \
  -m gpt-5.5 \
  -c model_reasoning_effort='"xhigh"' \
  -s workspace-write \
  "$PROMPT"
```

notes:

- use `model_reasoning_effort="xhigh"` for Codex "max thinking" on this CLI; a live probe confirmed Codex reports `reasoning effort: xhigh` and completed successfully.
- use `--dangerously-bypass-approvals-and-sandbox` only inside a disposable/external sandbox or when the user explicitly accepts that risk.
- add `--output-last-message /tmp/codex-result.md` for longer runs so the summary survives noisy logs.
- use `--json` only when you intend to parse event streams; normal text is easier for quick handoffs.

## before delegating

1. verify Codex is available: `command -v codex && codex --version`.
2. if auth matters, check `codex login status`; if it is broken, continue directly instead of getting stuck in an auth loop.
3. inspect enough of the repo to write a self-contained prompt. do not ask Codex to discover the entire universe when Fable can cheaply provide the target files, conventions, and intended outcome.
4. choose isolation:
   - same worktree for one simple, low-risk task;
   - fresh `git worktree` for risky edits, parallel agents, or anything that might collide with user work.
5. ensure no two agents write the same file.
6. if a cheaper/model-helper result is weak, escalate or redo the work without asking. cost is only a tiebreaker after intelligence and taste needs are met.

## task card template for Codex

```text
repo: /absolute/path/to/repo
branch/worktree: <current branch or worktree path>
role: bounded implementation worker using gpt-5.5 high/max reasoning

goal:
<one concrete implementation/search/test goal>

context:
- <facts Fable already learned>
- <relevant files and functions>
- <architecture/product/security decisions already made>

constraints:
- do not change <files/areas>
- preserve <public API/schema/style>
- keep changes minimal and idiomatic for this repo
- no commits, no pushes, no external deploys

required verification:
- run: <specific test/lint/build command>
- if the command cannot run, explain the exact blocker and the narrowest substitute check

return:
- files changed
- summary of behavior changed
- verification output
- if this was a review and no issues were found, say that clearly and name the inspected target
- risks or follow-up questions
```

## orchestration loop

1. Fable inspects the request and repo enough to define the first task card.
2. Fable sends one bounded task to Codex.
3. Codex edits/runs checks and reports back.
4. Fable inspects `git diff`, reads changed files, and reruns the relevant checks itself.
5. if the patch is wrong, Fable either fixes it directly when tiny or sends a narrower corrective task back to Codex.
6. repeat until the requested outcome is working and verified.
7. Fable gives the user a short report: changed files, checks run, remaining risks, and any command they need to run such as `stow claude`.

## when not to use Codex

- one-line docs/config edits where delegation overhead is silly.
- destructive operations, secret handling, live deploys, account deletion, billing, or public messaging.
- ambiguous product direction where the main work is deciding what should exist.
- final approval of security-sensitive changes.
- normal day-to-day Codex work outside a Fable session. this playbook is for Fable orchestrating helpers, not for changing Codex's own defaults.

## parallel delegation

for multiple independent tasks, use one worktree per task and one file ownership boundary per Codex run. Fable should coordinate shared decisions and merge/reconcile results. if the tasks are not independent, run them serially.
