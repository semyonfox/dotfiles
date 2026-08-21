---
name: claude-second-opinion
description: Use when asked for Claude, Fable, or a second opinion, or when uncertainty, a repeatedly failed fix, or high-risk diagnosis persists — not routine code reading.

metadata:
  harness: [codex]
---

# Claude Second Opinion

Bring in Claude as an independent reviewer only when it reduces uncertainty or unblocks a fix. Investigate locally first unless the user asks for Claude immediately.

## When to use it

Use it for an explicit Claude/Fable/second-opinion request; an ambiguity remaining after relevant code, logs, tests, or docs; a fix that has failed more than once; a high-impact change needing an independent sanity check before edit/deploy; or focused critique of a proposed remediation. Do **not** use it for routine reading, simple commands, obvious fixes, user-prohibited external services, or broad brainstorming. Its answer never replaces local verification.

## Command format

`claude -p fable` means the literal prompt `fable` to the default model. For Claude Code print mode with Fable, use `claude --model fable -p "prompt"`.

Default to this bounded, non-interactive, no-tools call:

```bash
timeout 180s claude --model fable -p \
  --max-turns 1 \
  --max-budget-usd 0.75 \
  --tools "" \
  "Review the context below and give a concise second opinion. Do not ask for tool access. Return: conclusion, reasoning, likely fix, and verification steps.

<context>
PASTE_REDACTED_CONTEXT_HERE
</context>"
```

If `timeout` is unavailable, omit it. If the installed version rejects a documented flag, retry with the smallest compatible command and state which flag was removed:

```bash
claude --model fable -p "PROMPT"
```

Use `--output-format json` for machine parsing or cost/session metadata; use text otherwise.

## Prompt and access boundaries

Give the smallest useful context: exact question; observed failing command/error, paths, relevant snippets, constraints, and attempts; ask it to challenge a weak diagnosis and propose concrete checks. Redact secrets, tokens, credentials, private keys, `.env`, customer data, and irrelevant personal data. Prefer `git diff --stat`, `git diff -- <file>`, short traces, and excerpts over repositories, long logs, or unrelated diffs.

Prefer pasted context and no tools. If repository inspection is genuinely needed, allow only read-only access to the current tree:

```bash
timeout 180s claude --model fable -p \
  --no-session-persistence \
  --max-turns 2 \
  --max-budget-usd 1.50 \
  --tools "Read,Glob,Grep,LS" \
  --add-dir "$PWD" \
  "Inspect this repository read-only and give a second opinion on: QUESTION_HERE. Do not edit files or run shell commands."
```

Never grant edit, write, bash, browser, MCP, or permission bypass for a second opinion unless the user explicitly requests active Claude work.

## Use the answer

Compare its claims with local code, tests, docs, and runtime behavior; use it to refine the plan or patch while retaining final engineering judgment; then run relevant local checks. Tell the user what was useful and whether you agreed, rejected, or partly used it.

## Docs checked

At creation, local CLI `claude 2.1.199 (Claude Code)`, `claude --help`, and the official Claude Code CLI reference confirmed `-p/--print`, `--model fable`, `--no-session-persistence`, `--output-format`, `--max-budget-usd`, `--max-turns`, `--tools`, and `--add-dir` for bounded scripts. Re-check `claude --help` and the official reference if flags fail or precision matters.
