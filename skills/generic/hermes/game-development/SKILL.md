---
name: game-development
description: "Use when shaping, prototyping, or scoping a game concept."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Game Development Workflow

## Use when

Use for game concepts, design reviews, prototype planning, vertical slices, gameplay loops, progression, platform strategy, and game-specific scope control. This is especially useful when a concept blends a distinctive theme with systems the creator already understands.

## Core principle: prove the loop before the game

A game proposal is not yet a game. Reduce it to the smallest repeatable player loop that creates readable pressure, a meaningful decision, and immediate feedback:

```text
pressure rises → player notices → player acts → system visibly changes → outcome is scored
```

Do not begin production with art pipelines, economy design, online services, platform integration, or a campaign map. First make this loop enjoyable using grey-box visuals and a short, authored scenario.

## Concept evaluation

For each concept, identify:

1. **Player fantasy:** What role does the player inhabit?
2. **One-sentence pitch:** Explain the game through a familiar comparison plus its differentiator.
3. **Core verbs:** Limit the first prototype to three to five direct actions.
4. **Pressure source:** What changes over time and forces decisions?
5. **Trade-off:** What does a correct action cost, sacrifice, or delay?
6. **Feedback language:** What can the player read at a glance—colour, movement, sound, queues, health, score?
7. **Finishable proof:** Define one short scenario with a win and failure condition.

A specialised real-world theme works best when it is translated into visual, intuitive decisions. Preserve the theme's logic but do not turn the game into a professional training interface.

## Scope a first playable

Target one 8–10 minute, scripted level. It should introduce one mechanic at a time, then combine them once:

1. Normal state: let the player read the system.
2. Rising demand: introduce a visible bottleneck.
3. New priority: require a trade-off rather than a cosmetic action.
4. Fault or complication: require adaptation.
5. Recovery: show the player that their intervention mattered.
6. Clear win/fail and restart loop.

Use an authored escalation curve before adding random events. Randomness obscures whether the underlying mechanics are fair and legible.

## Systems-simulation games

For a management game inspired by a complex technical system:

- Simulate aggregates, not the literal real-world units, unless literal fidelity is itself the product.
- Keep the model readable and tunable: graph nodes, connections, capacities, states, and demand classes are often enough.
- Allocate scarce capacity according to clear priority rules, then derive simple thresholds for the visual state.
- Render representative particles, alerts, and animations from aggregate state rather than simulating every object.
- Prefer consequences a non-expert can understand over technically exact but opaque mechanics.

## Online-first ideas: sequence them safely

Multiplayer shooters and other live games require networking, server operations, matchmaking, anti-cheat, moderation, balancing, and population health. Do not make public online multiplayer the first proof of a combat concept.

Safer progression:

1. Build an offline core prototype.
2. Add bots and validate weapons/maps/controls.
3. Test local or private multiplayer.
4. Validate a small hosted session.
5. Consider public matchmaking only after the game is already fun and supportable.

For mobile-first projects, defer accounts, cloud saves, ads, IAP, achievements, cross-platform release, and storefront integrations until the core game is proven.

## Mobile and monetisation principles

If the intended product rejects manipulative mobile design, encode that as a product constraint from the start:

- fast startup and efficient ordinary-device performance;
- offline play where possible;
- no forced account or persistent-server dependency;
- no energy timers, loot boxes, pay-to-win, or premium-currency maze;
- monetisation that does not sell relief from deliberately created frustration.

Potential models include a one-time full-game unlock, optional expansions, cosmetics, supporter packs, and clearly optional rewarded ads. Do not implement any of them in a grey-box prototype.

## Validation questions

Test a first playable with people unfamiliar with the theme. Ask and observe:

- Did they understand what was going wrong without an explanation?
- Did they know which actions were available?
- Did the feedback make the result of an action obvious?
- Did they replay voluntarily?
- Could they describe the game to someone else in one sentence?

Treat confusion as a design finding, not a player failure. Simplify the information hierarchy or scenario before adding more systems.

## Deliverables and handoff

Before implementation, produce:

- a one-page pitch;
- a diagram or sketch of the first level;
- a list of prototype verbs;
- simple simulation/interaction rules;
- explicit win and failure conditions;
- a v1 exclusion list.

Keep specific game concept notes in `references/`, starting with `references/network-infrastructure-management-game.md`.

## Pitfalls

- Mistaking a long progression outline for a scoped first build.
- Adding a campaign, economy, tech tree, random events, or visual polish before testing the loop.
- Simulating every real-world detail when a readable approximation would feel better.
- Making the user configure technical systems rather than make intuitive, time-pressured decisions.
- Treating a competitive online game as a simple extension of an offline prototype.
- Letting monetisation or platform work shape the prototype before there is evidence that players want to return.

## Verification checklist

- [ ] One-sentence pitch identifies a familiar genre and real differentiator.
- [ ] Prototype contains no more than five direct player verbs.
- [ ] First scenario is short, scripted, and has a clear recovery/win state.
- [ ] Feedback exposes pressure and consequence at a glance.
- [ ] Complex simulation is aggregate and tunable.
- [ ] Online and monetisation features are explicitly deferred unless essential to the core loop.
- [ ] At least one non-expert playtest is planned before expanding scope.
