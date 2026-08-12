---
name: kanban
description: "Use when routing durable multi-agent work through Hermes Kanban, including orchestrator/worker roles, parent links, blocking, completion, and recovery."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Hermes Kanban Workflow

## Overview

Use this skill when work needs to outlive a single turn, should be tracked across multiple agents, or benefits from explicit routing and durable state. Kanban is the board-backed workflow for decomposition, assignment, blocking, recovery, and completion.

This umbrella absorbs the former orchestrator/worker split into one class-level guide. The role you play determines which subsection matters most, but the board lifecycle is the same.

## When to Use

- The request needs multiple specialists or parallel lanes
- The work should survive a crash, restart, or interruption
- The user wants a durable handoff instead of ephemeral delegation
- You need dependency edges between tasks
- Review, approval, or human-in-the-loop gates matter

For small one-shot reasoning tasks, use direct execution or `delegate_task` instead of creating board overhead.

## Core Board Model

A Kanban task should carry:

- a clear title
- explicit acceptance criteria in the body
- a real assignee profile
- parent links only when a task truly depends on another task
- comments for durable context, especially when blocked or recovering

Independent tasks should be created in parallel. Dependent tasks should be linked from the start so the dispatcher can respect the graph.

## Orchestrator Role

If you are the routing/orchestration profile, your job is to decompose the request, map lanes to actual profiles that exist on this machine, and create the correct board graph.

Rules:

1. Discover the available profiles first.
2. Split independent lanes before creating cards.
3. Use parent links for real dependencies only.
4. Do not do the implementation work yourself.
5. Report the graph back to the user in plain language.

## Worker Role

If you are dispatched as a worker, your job is to execute the assigned lane, keep the board updated, and then either complete or block.

Good habits:

- read the task thread before touching files
- send heartbeats only when progress is meaningful
- complete with a concise summary and useful metadata
- block when you need a human decision or when the task is not truly finishable yet

## Completion and Blocking

Use `kanban_complete` when the task is terminal and done.
Use `kanban_block` when a decision, dependency, or review is required.

A good blocked task says exactly what decision is needed and leaves longer context in a comment.

## Recovery

When a task keeps failing, do not blindly rerun the same work. Inspect the prior run outcome, note the failure mode, and adjust one of:

- the workspace
- the profile
- the model
- the task decomposition

If the operator reclaims or reassigns the task, treat the board thread as the source of truth.

## Recurring-agent / cron workflow pilots

When moving an existing autonomous workflow from cron logs or ad-hoc reports onto Kanban, start with a conservative pilot rather than unleashing workers immediately:

1. Create a named board for the workstream instead of polluting `default`.
2. Seed a blocked parent tracking card that explains the pilot, acceptance criteria, and safety gates.
3. Seed child cards from the latest durable report/state using stable idempotency keys, so later cron runs update/comment rather than duplicate.
4. Keep human-gated cards blocked by default: PR review queues, dirty-checkout decisions, incident policy changes, and anything that could mutate repos or external systems.
5. Enable the `kanban` toolset on the relevant cron job and update its prompt to create/update Kanban cards for durable actions, blockers, handoffs, and audit history — not every scanned item.
6. Add a comment on the parent card recording what was wired and what remains intentionally blocked.
7. Verify with `hermes kanban --board <slug> stats` and `list`; there should be no accidental `ready/running` cards unless the user explicitly asked to activate work.

Use idempotency keys that encode the durable object, e.g. `repo-agent:pr:<repo>:<number>`, `repo-agent:blocker:<repo>:dirty-checkout`, `repo-agent:cleanup:<repo>:<artifact>`, or `watchdog:incident:<type>`. See `references/recurring-agent-kanban-pilot.md` for a concrete repo-agent/watchdog/briefing pattern.

## GitHub bridge for repo-agent workflows

When Kanban is used as the durable control plane for recurring repo-agent work, keep GitHub as the repo-visible truth. Kanban should track internal routing, blockers, handoffs, and human gates; GitHub should receive evidence-backed issues, feature requests, draft PRs, and project-board status. Use stable idempotency keys so cron runs update existing cards instead of duplicating them. See `references/github-repo-agent-bridge.md` for the issue/PR/project mapping, label set, body footers, and GitHub Projects auth/setup notes.

## Pitfalls

- If dispatched Kanban workers crash immediately with `Error: Unknown skill(s): kanban-worker`, the dispatcher/runtime is referencing a missing built-in/installed worker skill. Fix the skill/runtime wiring before re-queuing cards; otherwise every promoted card will fail twice and auto-block without doing work.
- Inventing profile names that do not exist
- Bundling unrelated work into one card
- Creating dependent cards as if they were independent
- Forgetting to comment before blocking on an important decision
- Repeating a failed run without learning from the prior attempt
- Treating Kanban as a replacement for GitHub Issues/PRs/Projects; it is the private workflow control plane, not the public repo truth
- Creating GitHub issues for local-only workflow blockers such as dirty checkouts or agent retry noise
- Treating Kanban as a noisy mirror of cron output; create cards only for durable actions, blockers, decisions, incidents, and handoffs
- Creating ready/running cards during a pilot when the user only approved setup/experimentation

## Repo-Agent / External Tracker Pattern

When Kanban is used for recurring autonomous repo work, keep the board as the private agent control plane and external trackers as repo-facing truth.

- Use a named board for the workstream instead of polluting the default board.
- Seed parent cards plus human-gated child cards as `blocked` when you are testing a new workflow; do not leave broad pilot cards `ready` by accident.
- Store dirty checkout blockers, retry history, duplicate cleanup, and human decisions in Kanban even when they should not become GitHub issues.
- For repo-facing findings, link out to GitHub issues/PRs and add reciprocal links back to the Kanban task.
- Use stable idempotency keys so recurring cron sweeps create/reuse cards rather than duplicating every run.
- If Project/issue sync is blocked by missing OAuth scopes or other setup, create one blocked Kanban card with the exact human action and continue the rest of the workflow.

## Verification Checklist

- [ ] Task graph reflects the actual dependency structure
- [ ] Assignees are real profiles on this machine
- [ ] Comments capture the context needed for future recovery
- [ ] Complete vs block decision is justified
- [ ] Board state matches the actual work status
- [ ] Recurring/external-sync workflows use idempotency keys and reciprocal links to issues/PRs/projects
