# Fable/Codex orchestration

Use this only when Fable is genuinely the better lead or the user explicitly asks for Fable-style orchestration. The objective is not for Fable to type every line: Fable decides, delegates compact bounded work to Codex, and verifies the result.

Shared defaults live in `@~/.claude/CLAUDE.md`.

## roles

- **Fable/Claude:** clarify the goal, inspect the repo, choose architecture and constraints, make product/security/taste calls, decompose work, inspect diffs, and accept or reject results.
- **Codex Terra, medium:** default worker for interactive bounded implementation, routine refactors, and focused review; it is preferred when a small diff and human steering matter.
- **Codex Sol:** medium for brief work needing stronger reasoning than Terra; high for difficult, well-scoped investigation or autonomous work. xhigh/max/Ultra require a stated reason and stop condition.
- **Codex Spark:** a single low-judgment repetitive unit only. Return compact structured facts; never give it broad edits or final judgment.
- **Codex Luna:** an orchestrated bulk/helper lane only. Use it for independent extraction, classification, or transformations; do not select it as an open-ended lead.
- **Gemini through `agy`:** the eyes. It reports visible evidence from screenshots, UI, diagrams, and images. It does not make taste, architecture, or product decisions.

Codex output is always a patch candidate. Fable runs at high reasoning, reads the diff, and re-runs relevant checks before claiming success.

## task card

```text
repo: /absolute/path/to/repo
branch/worktree: <path or branch>
role: bounded Codex worker

goal:
<one concrete outcome>

context:
- <relevant facts and files>
- <decisions already made>

reference material:
- source of truth: <spec, issue, existing implementation, docs, or screenshot>
- nearest local example: <path>
- acceptance examples: <input/output or visible expected result>
- non-goals: <explicitly excluded work>

constraints:
- do not change <areas>
- preserve <API/schema/style>
- no commits, pushes, PRs, deploys, destructive operations, or public messages

required verification:
- run: <specific command>
- if blocked: report the exact blocker and narrowest substitute check

minimum expected delta:
- files/behaviour/verification that should be sufficient: <...>

failed-hypothesis rule:
- after one failed approach, verify the premise against observed evidence before attempting a workaround

stop after:
- <exact terminal condition>

do not:
- expand into <next phase>
- make unrelated cleanup or refactors

return:
- files changed
- behaviour changed
- verification result
- risks or blockers
```

Default command:

```bash
codex exec \
  --cd "$REPO" \
  -m gpt-5.6-terra \
  -c model_reasoning_effort='"medium"' \
  -s workspace-write \
  --output-last-message /tmp/codex-result.md \
  "$PROMPT"
```

For risky or parallel edits, use one clean worktree per task and non-overlapping file ownership. Use `--dangerously-bypass-approvals-and-sandbox` only in a disposable external sandbox or with explicit approval.

## loop

1. Fable inspects enough to write one self-contained task card.
2. Codex performs only that card and stops at its terminal condition.
3. Fable reads the diff and verification evidence.
4. Fable accepts it, fixes a tiny issue directly, or sends one narrower corrective card.
5. Stop at the user-requested phase boundary. Propose a next phase; do not run it unasked.

## visual handoff

For image-dependent work, ask `agy` for observations only: exact text, layout, hierarchy, colours, spacing, component states, icons, clipping, contrast, anomalies, and confidence. Preserve those concrete observations and discard speculative recommendations before handing evidence to Fable or Codex.

```bash
IMAGE=/path/to/image.png
AGY_MODEL="Gemini 3.5 Flash (Low)"
agy --model "$AGY_MODEL" --mode plan --add-dir "$(dirname "$IMAGE")" --print-timeout 5m -p "Use Gemini vision on this image. Return observations only for another model: exact text, layout, colours, spacing, hierarchy, component states, icons, clipping, unreadable text, contrast issues, anomalies, and confidence. Separate observations from guesses. Do not recommend redesigns, architecture, or product decisions: $IMAGE"
```
