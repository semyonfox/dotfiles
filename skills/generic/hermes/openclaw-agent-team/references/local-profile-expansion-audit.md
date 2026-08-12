# Local Hermes Persona/Profile Expansion Audit

Use this reference when Semyon asks whether the local OpenClaw-style Hermes profiles/agents are good, stale, missing pieces, or worth expanding.

## What to inspect

1. `hermes profile list` for active profiles, aliases, model/provider, gateway state.
2. Each profile under `~/.hermes/profiles/<name>/`:
   - `profile.yaml` description and `description_auto`.
   - `SOUL.md` identity, scope, operating style, permission posture, and output style.
   - `config.yaml` model/provider, `agent.personalities`, memory, toolsets, and skill availability.
3. Compare profile skill trees against default:
   - Look for missing class-level skills that matter to a persona, especially homelab/devops skills for Chuck, Sean, R2D2, and Theo.
4. Check whether profiles have their own session history/state yet:
   - Absence of profile-specific `state.db` usually means the profile exists but has not built much lived experience.
5. Inspect default cron jobs when evaluating operational maturity:
   - Persona-labelled jobs may run from default because default owns the gateway; that is acceptable, but call out whether the persona is only a label or has real workflow depth.

## Assessment lens

Distinguish three maturity levels:

- **Persona shell**: good `SOUL.md`/description, but mostly cloned config and no profile-specific skills, cron, workdirs, or session history.
- **Specialist assistant**: distinct skills, default first moves, project/workdir expectations, and explicit routing/handoff rules.
- **Operational agent**: owns recurring checks, scripts, cron jobs, kanban lanes, or verified workflows with low-noise reporting.

Do not recommend adding more characters by default. Prefer deepening existing profiles with workflows, skills, and automation.

## Common improvement checklist

- Ensure every profile knows the full team roster in `agent.personalities` when that roster is part of the operating model.
- Sync missing relevant umbrella skills across profiles, especially:
  - Chuck/Sean/R2D2: homelab, Docker, networking, monitoring, backups.
  - Theo: code inspection, debugging, TDD/review, app deployment context.
  - Camille: planning/productivity, writing, task routing.
  - Eidhne: social/support and light technical triage.
- Add a `Default First Moves` section to each persona `SOUL.md`:
  - Camille: objective, constraints, next 3 actions, kill/defer list.
  - Theo: inspect repo, reproduce, small verified patch, tests/build output.
  - Chuck: map client → DNS → proxy/tunnel → host → container → app → data.
  - R2D2: severity first, evidence second, recommendation third; separate current failures from stale log noise.
  - Sean: severity/evidence/fix/verify/document for incident-style work.
  - Eidhne: reduce overthinking, one concrete next action, keep advice non-cringe.
- Prefer class-level skills over one-off notes, e.g. `r2d2-system-watchdog`, `chuck-traffic-path-debugging`, `theo-project-debugging`, or broader umbrellas if those already exist.
- Keep monitoring automations script-only and silent unless something needs attention; avoid noisy all-clear spam.

## Reporting style for audits

Give a candid, ranked assessment:

- What exists and what state it is in.
- What is genuinely good.
- What is only persona/theatre versus operational depth.
- The smallest high-ROI fixes first.
- Avoid turning the answer into a migration epic unless Semyon asks to implement it immediately.
