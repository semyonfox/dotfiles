---
name: claude-second-opinion
description: "Use when asked for Claude, Fable, or a second opinion, or when uncertainty, a repeatedly failed fix, or high-risk diagnosis persists — not routine code reading."

metadata:
  harness: [codex]
---

# Claude Second Opinion

Use this skill to bring in Claude as an independent reviewer when another model pass is likely to reduce uncertainty or unblock a fix. Do the local investigation first unless the user directly asks to ask Claude immediately.

## Use Judiciously

Ask Claude when one of these is true:

- The user explicitly asks to call Claude, Fable, or get a second opinion.
- A bug or design issue remains ambiguous after reading the relevant code, logs, tests, or docs.
- A fix has failed more than once and a fresh diagnosis could expose a missed assumption.
- The issue is high impact and warrants an independent sanity check before editing or deploying.
- You need a focused critique of a proposed remediation, not broad brainstorming.

Do not ask Claude for routine code reading, simple commands, obvious fixes, or tasks where the user has asked not to use external services. Do not let Claude's answer replace local verification.

## Command Format

Interpret the user's shorthand `claude -p fable` as "use Claude Code print mode with the Fable model." The correct documented shape is `claude --model fable -p "prompt"`. A bare `claude -p fable` sends the word `fable` as the prompt to the default model.

Default to a non-interactive, bounded, no-tools call:

```bash
timeout 180s claude --model fable -p \
  --no-session-persistence \
  --max-turns 1 \
  --max-budget-usd 0.75 \
  --tools "" \
  "Review the context below and give a concise second opinion. Do not ask for tool access. Return: conclusion, reasoning, likely fix, and verification steps.

<context>
PASTE_REDACTED_CONTEXT_HERE
</context>"
```

If `timeout` is not available, omit it. If a documented flag is rejected by the installed Claude version, retry with the smallest compatible command and note the removed flag:

```bash
claude --model fable -p "PROMPT"
```

Use `--output-format json` when the result needs to be machine-parseable or when cost/session metadata is useful. Use text output for ordinary second-opinion reads.

## Prompt Hygiene

Give Claude the smallest useful context:

- State the exact question to answer.
- Include observed facts: failing command, error excerpt, relevant file paths, key code snippets, environment constraints, and what has already been tried.
- Ask for disagreement explicitly: "Challenge my likely diagnosis if it is weak."
- Ask for concrete checks, not just an opinion.
- Redact secrets, tokens, credentials, private keys, `.env` content, customer data, and irrelevant personal data.

Avoid dumping an entire repository, long logs, or unrelated diffs. Prefer `git diff --stat`, focused `git diff -- <file>`, stack traces, and short code excerpts.

## Read-Only Repository Access

Prefer no-tools calls with pasted context. If Claude genuinely needs to inspect files itself, restrict it to read-only tools and the current working tree:

```bash
timeout 180s claude --model fable -p \
  --no-session-persistence \
  --max-turns 2 \
  --max-budget-usd 1.50 \
  --tools "Read,Glob,Grep,LS" \
  --add-dir "$PWD" \
  "Inspect this repository read-only and give a second opinion on: QUESTION_HERE. Do not edit files or run shell commands."
```

Do not grant edit, write, bash, browser, MCP, or permission-bypass capabilities for a second opinion unless the user explicitly asks Claude to do active work.

## Use The Answer

After Claude responds:

1. Compare its claim against the local code, tests, docs, and runtime behavior.
2. Use the answer to refine the plan or patch, but make the final engineering judgment yourself.
3. Run the relevant local checks after implementing any change.
4. In the user-facing response, summarize the useful part of Claude's second opinion and call out whether you agreed, rejected, or partially used it.

## Docs Checked

At skill creation, the local CLI was `claude 2.1.199 (Claude Code)`. `claude --help` and the official Claude Code CLI reference confirmed that `-p/--print` is non-interactive print mode, `--model fable` selects the Fable model alias, `--no-session-persistence`, `--output-format`, `--max-budget-usd`, `--max-turns`, `--tools`, and `--add-dir` are relevant for bounded scripted use. Re-check `claude --help` and the official CLI reference if a flag fails or precise behavior matters.
