---
name: autonomous-ai-agents
description: "Use when delegating code or repo work to external autonomous coding agents, choosing among Claude Code, Codex, and OpenCode, or repairing T3 Code mobile APK automation. See references/t3-code-mobile-watcher-repair.md for resilient mobile-source reconciliation and generated Android-tree repair."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Autonomous AI Agents

## Overview

Use this skill when the user wants Hermes to hand off coding, refactoring, review, or long-running repo work to an external autonomous agent CLI. The three common choices are Claude Code, Codex, and OpenCode.

This is an orchestration skill, not a model-comparison essay. The goal is to pick the right agent, launch it with the right level of autonomy, and verify the result without losing control of the repo or the session.

## When to Use

- The user explicitly asks for Claude Code, Codex, OpenCode, OpenClaw, or another autonomous-agent runtime
- You want an external coding agent to implement, refactor, or review code
- The task is long-running and benefits from background monitoring
- You need a separate agent to operate in a repo/worktree while Hermes stays in charge
- You are comparing agent CLIs or checking which one is installed and authenticated
- The user asks to check coding-agent usage, spend, active limits, active blocks, or remaining quota for Claude Code, Codex, or similar CLIs
- You are troubleshooting a coding-agent control-plane app such as T3 Code, especially saved environment, SSH pairing, provider auth, or credential persistence failures
- You are auditing, preserving, exporting, deduplicating, or deciding whether to delete local AI-agent corpora such as `.codex`, `.codex-merge-backup`, `.t3`, `.claude`, `.hermes`, OpenCode, Cursor, or Antigravity/Gemini stores
- You are comparing or migrating a named multi-persona agent setup into Hermes profiles, skills, channel bindings, cron jobs, or kanban

Do not use this skill for simple shell commands, one-file edits, or tasks Hermes can finish directly and safely.

## Choosing the Agent

| Need | Best fit | Why |
|---|---|---|
| Strong interactive coding flow with print mode and TUI | Claude Code | Mature print mode, worktree support, good review workflows |
| OpenAI-native coding agent / Codex ecosystem | Codex | Best fit when the user is already on OpenAI/Codex auth |
| Visual-description worker for screenshots/UI/images | Antigravity CLI (`agy`) + Gemini | Gemini is efficient and unusually strong at visual detail extraction; use it to produce dense handoff context, not as the lead reasoning/coding brain |
| SVG cleanup / imagery generation-editing | GPT-5.5/5.6 lead, escalate to Fable on Claude when better | Use GPT-5.5/5.6 as the normal lead if good enough; use Fable when it is materially better for taste/cleanup/generation quality. Pair either lane with Gemini/Antigravity visual QA when visual fidelity matters |
| Provider-agnostic open-source worker | OpenCode | Good when the user explicitly wants OpenCode or a flexible model setup |

If the user did not specify, choose the agent that is already installed and authenticated, and prefer the shortest safe workflow that can complete the task.

## Common Orchestration Rules

1. **Verify readiness first.** Check binary, version, and auth/status before relying on the agent. For Claude `-p` runs that include the variadic `--allowed-tools` option, put `--` before the prompt so the CLI does not consume the prompt as another allowed-tool value:

   ```bash
   claude -p --model fable --allowed-tools 'Read,Glob,Grep,Bash(git *)' -- 'Review this diff read-only.'
   ```

   A tiny exact-output probe with the same option shape is the fastest validation before launching expensive/background reviews.
2. **Use the right execution mode.** One-shot mode for bounded tasks; interactive/background mode only when iteration is needed.
3. **Scope the workspace.** Use a repo-specific `workdir`, and prefer isolated worktrees for parallel edits.
4. **Encode routing rules into the relevant agent guidance when asked.** If Semyon points at a workflow tip such as Claude/Fable using Codex as a fallback to reduce token pressure, treat the likely deliverable as an update to global/project agent instructions, not an essay. Preserve stow-managed sources and live files, verify Claude/Codex binaries and auth, and phrase the rule as Claude plans/reviews while Codex handles bounded implementation/search/test work. See `references/claude-codex-routing-guidance.md`.

### Instruction-library maintenance

When reducing prompt/skill context, classify instruction surfaces before deduplicating. Claude global guidance, Codex guidance, local `AGENTS.md`, and a task playbook can be loaded independently; each needs a compact standalone fallback for model choice, stop conditions, and safety. Reduce tokens **within** a surface first: collapse duplicated sections, turn long reference catalogues into a short discovery pointer, and move specialised diagnostics into `references/`. Measure before/after size, preserve critical guardrails, and verify Stow source/live parity. Before using `stow` to deploy one changed guidance file, dry-run it; if an existing broad package conflicts, do not force/adopt it—compare the intended source and live target, then perform a narrow verified sync when authorized.
5. **Use Codex Spark as a helper lane, not a lead.** Score `codex-spark` / `gpt-5.3-codex-spark` as cost 10, intelligence 2, taste 1 on the 1-10 higher-is-better routing scale: practically free / can be driven hard for Semyon's setup, able to follow narrow templates and extract obvious facts, but not clever or taste-bearing. Route low-intelligence repetitive single-file work — per-file summaries, simple extraction/classification, boilerplate cleanup, and compact fact gathering — to Codex Spark when it saves the bigger agent's context. Give Spark one file or independent unit, forbid broad repo edits, request compact structured output, and have the lead agent synthesize/verify.
6. **For Semyon's Codex $100/month plan, route by task shape.** Default interactive implementation, routine repo work, bounded refactors, and focused review to `gpt-5.6-terra` at medium: it is the small-diff/human-steered workhorse. Use `gpt-5.6-sol` at medium for short work that needs stronger reasoning, and at high for difficult, well-scoped investigations, architecture decisions, multi-step debugging, or autonomous bounded tasks likely to take more than about ten minutes. Treat Sol xhigh/max/Ultra as explicit escalation modes only after a normal pass demonstrates a capability gap; state the reason and terminal condition. Treat Luna as an orchestrated bulk/helper lane, and Spark as a single low-judgment repetitive unit, never a manually selected open-ended lead. Do not preserve stale model-score tables as durable routing truth; model availability and quotas change, so verify locally when the exact model matters.
7. **Encode phase boundaries in every long worker prompt.** GPT-5.6 can complete lengthy work but may continue polishing or expanding scope after the useful terminal point. Task cards must state the phase (`plan`, `implement`, `review`, `PR`), an explicit `stop after:` condition, the required verification, and prohibited next phases. For example: plan then stop for approval; implement and run named checks then stop; or address only the first review round then stop. Propose a next phase in one line instead of executing it.
   - For Sol work, also state the minimum expected delta, nearest local reference, explicit non-goals, and the evidence that proves success. It can turn a small request into an unnecessary rewrite or speculative test matrix without these constraints.
   - After one failed hypothesis, require a premise check against observed evidence before a new workaround. Sol's persistence is valuable, but it can pursue a non-existent problem or keep an incorrect assumption alive.
8. **Use Antigravity/Gemini for visual handoff, not Hermes provider config, unless explicitly requested.** If Semyon wants Gemini for screenshots, UI layouts, diagrams, or visual QA, call `agy`/Gemini as a visual-description worker and feed the dense description to Claude/Codex/Fable. Do not redirect the task into Hermes `auxiliary.vision` setup when he asked for `AGENTS.md`, `CLAUDE.md`, or skill-level routing. See `references/antigravity-gemini-vision-handoff.md`.
7. **Keep Hermes in the loop.** Monitor progress, capture logs, and summarize concrete changes back to the user. If the user withdraws delegation mid-task (for example, “don’t delegate”), cancel queued child work and complete the remaining scope directly; do not keep background delegated work running or treat the correction as a permanent no-delegation preference for unrelated tasks.
7. **Verify child-agent self-reports before telling Semyon something changed.** After delegated repo work, the parent must inspect `git status`, `git diff --stat`, and the relevant file/diff itself. Child agents can confidently claim a dependency was removed or a file was written when verification shows it was not; treat summaries as leads, not truth.
8. **Do not let the agent roam.** Restrict tools or permissions when the CLI supports it.
9. **For recurring repo-agent loops, use staged disposable contexts.** Hermes should schedule/orchestrate and pass compact task cards between GitHub checker, reviewer, planner, implementer, verifier, and reporter stages. Codex should work in isolated worktrees; Claude Code can provide second-opinion read-only review for high-risk or ambiguous changes. See `references/hermes-codex-repo-agent-loop.md`.
10. **Avoid context rot in multi-repo loops.** Use Hermes cron as the thin scheduler, per-repo orchestrator runs for repo state, and fresh/focused Codex threads for PR review, implementation, and verification. Pass compact structured summaries and handles between layers rather than full transcripts or cross-repo context. See `references/repo-agent-loop-with-codex-worktrees.md`.
11. **Use allowlists for recurring repo loops.** When building a scheduled maintainer loop across local repos, curate included projects first; exclude external clones, templates, coursework, notes, inactive experiments, upstream/reference repos, and one-off prototypes unless the user explicitly revives them.
12. **Treat allowlist removals as active configuration changes.** If the user says to remove a repo/project from a recurring repo-agent allowlist, update the scheduler/cron prompt or allowlist source immediately, verify the project path/name has zero remaining active occurrences, and report the new allowlist count. If that repo has an open agent PR, do not merge it just because other easy PRs are being merged unless the user explicitly asks.
13. **Fan out scheduled multi-repo sweeps.** If the user expects "all repos" or complains a repo-agent cron is only doing one tiny thing, treat it as a workflow bug: enable the `delegation` toolset for the cron job, raise child concurrency where appropriate, and require parallel waves until every allowlisted repo has a result card. Use aggressive coverage with conservative mutations. If Semyon explicitly asks for "max spread" / "no context rot", make the parent cron agent a reducer/orchestrator only: one repo worker per allowlisted repo, focused per-task subagents inside each repo when useful, compact JSON batons/cards only, no early stop after the first PR, and degraded fan-out metrics if capacity falls back. See `references/repo-agent-cron-fanout.md`.
14. **Do not let dirty normal checkouts become fake blockers.** For recurring repo agents, dirty user work in the main checkout means "do not touch that checkout," not "do nothing." Fetch remote state and create a fresh isolated worktree from `origin/<base>` for unrelated safe work. Block only when the candidate specifically depends on uncommitted user files, repo metadata/remotes are unusable, no safe remote base exists, a fresh lock exists, or project safety policy forbids action. Verify the worktree is clean and on an `agent/*` branch before implementation. If the clean worktree reveals that the selected issue refers to local-only uncommitted files, report that exact blocker instead of copying dirty files across. Existing draft PRs are also not a repo-wide stop sign: inspect/update them first, then allow additional non-overlapping draft PRs when deduplication passes.
15. **Use a top-level run mutex for scheduled repo-agent loops.** Per-repo locks are not enough: overlapping cron/manual triggers can duplicate GitHub issues, Kanban cards, and report writes. Acquire `/home/semyon/.hermes/repo-agent/run.lock` or equivalent before scanning/mutating; fresh duplicate runs should go silent, stale locks should be recovered only after checking no matching process is active. See `references/repo-agent-run-mutex-and-dirty-worktrees.md`.
16. **Autonomous-to-draft-PR is the target, not issue-only triage.** When work is scoped, evidence-backed, and testable, repo-agent loops should create a fresh clean worktree from `origin/<base>` / the last remote commit on an `agent/*` branch, implement the bugfix/feature/test/docs/CI/security-config hygiene task, run meaningful checks, open or update a draft PR, link the GitHub issue and Kanban card, then clean up the disposable worktree when safe. Dirty normal checkouts are preservation boundaries only, not repo-wide blockers. Stop at an issue/Kanban card only when product direction, unsafe data/secrets/live APIs, or user-work preservation genuinely requires approval.
17. **Keep merges human-gated.** Agent loops may open issues, review PRs, push to agent-owned branches, and open draft PRs, but must not merge to protected branches like `main` or `dev` without explicit approval.
19. **For retrospective workflow summaries, reconcile sessions into net changes.** When Semyon asks what the agent workflow did "last night", "today", or "up to now", identify the cron job, read recent run summaries and the latest repo-agent report, verify current PR state with GitHub where practical, then report sweeps, repo touches, net PRs/issues/comments, per-repo changes, checks, blockers, and next actions. Avoid double-counting PRs that appeared in multiple sweeps. See `references/repo-agent-retrospective-summary.md`.
20. **Separate configured capability from observed behavior when judging whether the repo-agent is "working properly" or using Hermes features effectively.** Read the cron prompt/config for intended phases, but validate with the latest report metrics and live GitHub state. Call out mismatches plainly — e.g. `delegation` enabled but `delegated_scouts: 0`, Project sync configured but blocked by missing `project/read:project` scopes, or draft PRs open/green but awaiting human review. Also check strategic priority alignment: a pipeline can be technically healthy while spending cycles on low-priority repos and only scanning OghmaNotes/swim read-only. In that case, recommend routing fixes such as priority-specific cron jobs, higher safe artifact targets, or stricter clean-worktree escape hatches. See `references/repo-agent-health-check.md`. This avoids over-claiming that the whole pipeline is healthy just because the cron status is `ok`.
21. **Treat local agent histories as preservation data before cleanup.** When Semyon asks if `.codex`, `.codex-merge-backup`, `.t3`, `.claude`, `.hermes`, OpenCode, Cursor, or Gemini/Antigravity stores can be deleted/merged/exported, inspect read-only first and compare by content hash, relative path, JSONL parseability, semantic event keys, and SQLite table counts. Do not live-merge backup JSONL into active agent runtime stores by default; build a separate normalized corpus with provenance and conflict variants. Deleted/tombstoned T3 rows may still contain valuable training messages/activities/events. See `references/agent-corpus-preservation-and-codex-backups.md`.

## Usage and Limit Audits

### Subscription proxy / router safety

When a user asks to set up, review, or troubleshoot an LLM proxy/router that can translate Claude/Codex/Gemini-style clients or reuse OAuth/subscription accounts, establish the actual billing path before recommending it. A protocol proxy is not a budget controller. Keep native subscription CLIs on native auth by default; make any cross-provider proxy route an explicitly named, temporary command/profile, never an ambient wrapper environment. Require a tiny end-to-end probe proving client → endpoint → upstream account → actual model → effort → quota lane. Do not default wrappers, cron, subagents, or "fast" model aliases to high/xhigh reasoning or one premium model. Preserve cheap lanes, cap concurrency, and require hard per-provider/account daily/weekly and per-task circuit breakers before sustained work. See `references/subscription-proxy-and-quota-guardrails.md`.

When Semyon asks to check coding-agent usage, spend, current limits, or remaining quota, prefer `bunx ccusage` for usage data and the native CLIs for auth/health. Run `bunx ccusage claude blocks --active --timezone Europe/Dublin` for Claude's active session block, `bunx ccusage claude daily --since YYYY-MM-DD --timezone Europe/Dublin --json` for exact recent Claude usage, and `bunx ccusage codex daily --since YYYY-MM-DD --timezone Europe/Dublin --json` plus `bunx ccusage codex monthly --timezone Europe/Dublin --json` for Codex. Pair that with `claude auth status`, `codex login status`, and `codex doctor` when the user asks about limits or account readiness.

Report usage and limit visibility separately. If the CLI exposes auth/subscription and spend but not remaining quota, say that directly rather than implying a remaining limit was checked. When the question is about Hermes running through Codex/OAuth, also inspect Hermes config, context resolver behavior, compression settings, and `~/.hermes/state.db`; Hermes may mark `openai-codex` as subscription-included even while `ccusage` shows API-equivalent dollars. See `references/coding-agent-usage-and-limit-audit.md` for the command set and `references/hermes-codex-token-accounting.md` for Hermes/Codex context, loop-record, and billing interpretation.

## Codex Doctor and guidance-maintenance repairs

When Codex Doctor reports installation/update path drift, distinguish the executable's package root from the active shell's `npm prefix -g`; align the executable to the configured npm root rather than changing a broad prefix blindly. Preserve any displaced wrapper and empty rollout artifacts under `~/.codex/repair-backups/`, then re-run Doctor. If the databases are healthy, do not hand-edit SQLite merely to silence historical missing-rollout references.

For global agent-guidance refreshes, keep the Stow source and live files synchronized, consolidate routing into one shared Claude policy plus a linked Fable/Codex playbook, and keep Codex's own AGENTS self-sufficient. Put Codex `model` and `model_reasoning_effort` at TOML top level, then verify Doctor reports the effective model. Before running `stow <package>`, dry-run it: a broad package can conflict with pre-existing non-symlinked skills and guidance. Do not force or `--adopt` the whole package just to deploy one policy file; compare the intended source and live target, then make a narrowly verified live-file sync when authorized, and report the wider Stow conflict separately. The detailed repair and verification recipe is in `references/codex-doctor-and-ai-guidance-hygiene.md`.

## Local Agent-Session Corpus Audits

When Semyon asks for a review of how he uses AI, agents, or models, audit the local Hermes session corpus before offering conclusions. Treat it as an operational review, not a generic model-comparison essay.

1. Establish scope: date range, total sessions/messages, and distinguish parent sessions from `subagent` and `cron` runs.
2. Query session-store aggregates by source and model: sessions, tool calls, input/output/reasoning tokens, billing mode, and the largest sessions by tool/message count.
3. Sample representative user prompts and explicit quality corrections. Infer working style from demonstrated behaviour, not just profile memory.
4. Inspect the *live* Hermes status/config, profiles, enabled toolsets, and cron list separately from historical session records. Historical model distribution shows what ran; the live default/provider shows what will run now.
5. Explain the mechanism precisely: multiple agents using the same model provide isolation and parallelism, not independent model judgement. Separate configured capability from observed usage.
6. Report security findings without reproducing sensitive values. If credentials were pasted into persistent chat history, recommend rotation and moving the workflow to a secret manager, environment file, or native interactive authentication.
7. Give a compact, opinionated operating model: task modes (investigate/review/plan/implement/operate), bounded task cards, evidence-based worker handoffs, phase-boundary session resets, and independent review only where the risk justifies it.

**Pitfalls:** Do not call subscription-included / zero recorded API cost “free.” Do not claim Claude or Gemini were Hermes model lanes merely because their external CLIs were used elsewhere; verify Hermes provider auth and recorded session models. Do not overstate a cron pipeline as healthy solely because its last run says `ok`; its intended design and observed reports/artefacts are separate questions.

## Claude Code

Use Claude Code when you want a strong general-purpose coding worker with both print mode and interactive TUI support.

### Read-only Fable review invocation

For a Claude/Fable `-p` review that restricts tools with `--allowed-tools`, terminate the option's variadic value list with `--` before the prompt. Without it, Claude can consume the prompt as another allowed-tool value and exit with “Input must be provided.” Example:

```bash
claude -p --model fable --effort medium --max-turns 16 \
  --allowed-tools 'Read,Glob,Grep,Bash(git *),Bash(gh *)' -- \
  'Review this PR read-only; do not edit, push, comment, or merge.'
```

Keep the review task card tightly bounded. For a broad queue, ask one Fable run to cover one repository or split a conflicted PR from unrelated local WIP; if it reaches its turn limit without a verdict, retry with a narrower evidence-first prompt rather than treating partial tool exploration as review completion.

Typical patterns:

```bash
claude -p 'Fix the failing auth tests' --allowedTools 'Read,Edit,Bash' --max-turns 10
```

### Read-only Fable / Claude review jobs

For a second-opinion review, explicitly constrain the prompt to read-only work and use an allowlist such as `Read,Glob,Grep,Bash(git *),Bash(gh *)`. **Put `--` immediately before the positional prompt** when using `--allowed-tools`: that option accepts variable arguments and can otherwise consume the prompt, causing Claude print mode to fail with an input-missing error.

```bash
claude -p --model fable --effort medium --max-turns 16 \
  --allowed-tools 'Read,Glob,Grep,Bash(git *),Bash(gh *)' -- \
  'Read-only review: inspect the PR diff and return MERGE, HOLD, or NEEDS-CHANGES. Do not edit, push, comment, or merge.'
```

For broad PR queues, split a reviewer into bounded PR or local-patch jobs rather than letting one run exhaust its turn budget. Treat an exhausted run without a final verdict as **no review**, then retry with narrower scope or more turns. Capture its output to a file, inspect that file rather than the terminal dashboard banner, and verify `git status`/`git diff --check` afterwards. Claude review remains advisory: re-check current PR state and substantive CI immediately before promotion or merge.

Use interactive mode only when you need a live loop, slash commands, or multi-step review/fix cycles. Prefer `tmux` plus `capture-pane` for monitoring.

## Codex

Use Codex when the user wants the OpenAI Codex CLI or when the workflow is already centered on the OpenAI auth path.

Typical patterns:

```bash
codex exec 'Add validation to the settings form' 
```

For longer tasks, run it in the background with a PTY and monitor via Hermes process tools. If the repo is missing, create a temporary git repo first; Codex expects one.

For recurring maintainer loops, prefer Codex sessions scoped to isolated worktrees and agent-owned branches. The control loop should review diffs, trace impacted code paths, run checks, and open draft PRs, while preserving a human approval gate for merges to `main`, `dev`, or release branches.

## OpenCode

Use OpenCode when the user explicitly asks for it or when a provider-agnostic open-source agent is the best fit.

Typical patterns:

```bash
opencode run 'Refactor the logging layer and update tests'
```

Interactive OpenCode sessions are fine for iterative work, but remember to exit with Ctrl+C, not `/exit`.

## T3 Code Troubleshooting

T3 Code (`pingdotgg/t3code`) is a coding-agent control plane, not a generic T3/Next app. For saved SSH environments, start with credential persistence/keyring state; for reconnects, verify the actual binary/version, duplicate SQLite writers, and pairing/provider locks; for pairing, preserve a healthy server and mint a short-lived reachable token privately. For Android watcher source failures, verify refs/tags before touching Android tooling and use deterministic stable-tag selection. Load the matching `t3-code-*.md` reference for commands and full diagnostics.

## OpenClaw / Persona-Team Migration

When the user asks how an OpenClaw-style set of named personas maps to Hermes, do not treat it as merely a model/provider comparison. Inspect the old agent config and persona files, then map concepts explicitly:

- OpenClaw agents/workspaces → Hermes profiles when strong isolation is needed.
- OpenClaw persona prompt files → Hermes skills, with bulky detail in `references/`.
- OpenClaw channel-to-agent routing → Discord/Slack `channel_skill_bindings` plus optional `channel_prompts`.
- OpenClaw monitoring/briefing personas → Hermes cron jobs loading the relevant skill.
- OpenClaw team handoffs → Hermes delegation or kanban depending on whether the work is short-lived or durable.

See `references/openclaw-to-hermes-persona-teams.md` for a concise migration map and comparison language.

## Repo-Agent Orchestration Pattern

Use Hermes as scheduler/orchestrator, GitHub as durable state, Codex as bounded worktree workers, and optional Claude Code for high-risk review. Apply the run-mutex and clean-worktree rules above before any scan or mutation.

The preferred shape is a staged pipeline:

1. GitHub checker / repo-state stage using `git` + `gh`.
2. Issue-finder / PR-review stage with fresh focused Codex review threads where useful.
3. Planning stage that receives a compact task card, not a transcript.
4. Implementation stage using `codex exec` inside an isolated `agent/*` worktree.
5. Independent review/verification stage, optionally with Claude Code in read-only/planning mode for high-risk changes.
6. Final reporting back to the user, with no auto-merge.

Pass compact structured handoffs only: repo, issue/PR number, branch, worktree, changed files, checks run, verdict, blocker, and next action. Keep durable truth in GitHub issues/PRs/branches and small JSON reports, not in model memory. See `references/repo-agent-orchestration.md` for the full workflow, handoff template, context-budget guidance, and second-opinion reviewer command.

For the print-mode Fable/Claude read-only review invocation, variadic `--allowed-tools` delimiter, turn-budget retry pattern, and post-review verification, see `references/claude-print-readonly-review.md`.

## Pitfalls

- Verify the local binary and auth instead of assuming names, paths, or quotas.
- Treat agent summaries as leads: inspect diffs, checks, and live state before claiming success.
- Keep Gemini as visual evidence, not the final product/taste/architecture judge.
- Keep workers isolated; use bounded task cards and never auto-merge protected branches.
- Do not post T3 pairing links publicly or treat a healthy HTTP endpoint as proof of healthy T3 state.
- Preserve agent-history stores read-only first; do not live-merge or delete them from filename matching alone.
## References

Open the named `references/*.md` when its scenario applies; the skill loader lists available files. High-value entry points: `claude-codex-routing-guidance.md`, `antigravity-gemini-vision-handoff.md`, `coding-agent-usage-and-limit-audit.md`, `repo-agent-orchestration.md`, `repo-agent-run-mutex-and-dirty-worktrees.md`, and `agent-corpus-preservation-and-codex-backups.md`.

## Verification Checklist

- [ ] Binary and version checked
- [ ] Auth or status check passed
- [ ] Correct execution mode chosen
- [ ] Workspace scoped to the intended repo or worktree
- [ ] Progress monitored for long tasks
- [ ] Result summarized with concrete file/test outcomes
