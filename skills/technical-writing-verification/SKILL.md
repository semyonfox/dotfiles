---
name: technical-writing-verification
description: "Verify technical product-writing claims against source code, history, tests, and domain rules before drafting or publishing."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Technical Writing Verification

Use for blog posts, case studies, release notes, portfolio pieces, engineering explainers, and review previews that make claims about a software system's rules, algorithm, performance, or history.

## Core principle

Never derive user-facing domain rules solely from algorithm names, state-machine shapes, issue handoffs, code comments, performance numbers, or a prior draft. Those sources can describe different layers of truth.

Keep these separate in every explanation:

1. **Domain rule** — what a valid result means to the user.
2. **Historical implementation** — how the old code attempted to satisfy that rule.
3. **Current implementation** — how the present code satisfies it and any internal technique it uses.
4. **Observed evidence** — what tests, benchmarks, or history actually demonstrate.

A brute-force implementation does not mean the domain rule itself is inherently complex. Conversely, a simple-looking UI can conceal a constrained assignment problem.

## Before writing

1. Locate the repository and inspect its working-copy state; do not disturb unrelated work.
2. Read the rule/validation boundary first: types, constants, validation helpers, and UI labels.
3. Read the implementation responsible for each behaviour being described.
4. Read focused tests that state the invariant. Use Git history when the narrative compares a previous implementation with the current one.
5. Make a short internal rule table before drafting:
   - allowed categories and exact product labels;
   - eligibility/filtering conditions;
   - required assignment/order constraints;
   - non-overlap or ranking semantics;
   - estimate/fallback behaviour, if relevant.
6. Run the focused rule tests before calling a claim verified.

## Writing method

- Explain the domain rule in ordinary language before naming an algorithm.
- Use the product's own category labels where that prevents ambiguity.
- Attribute historical weaknesses to the historical implementation, not to the underlying problem.
- Explain internal techniques only in terms of the user-facing constraint they resolve.
- Separate exactness scope from performance claims. For example, state whether an optimiser is exact for each selection pass or globally optimal across a collection of teams.
- Keep examples faithful to actual ordering and eligibility rules.

## Correction protocol

When a user flags a rules explanation as wrong:

1. Stop defending or incrementally rationalising the draft.
2. Re-read the rule/validation layer, implementation, and focused tests.
3. Identify which layer was conflated: rule, old code, current code, or evidence.
4. Rewrite the complete affected section around the verified rule table; do not merely swap terminology in isolated sentences.
5. Re-run focused tests and review the rendered draft before replacing any external review page.
6. Tell the user plainly what was wrong and what source established the correction.

## Draft-preview discipline

For externally hosted review drafts:

- Keep the canonical source outside production content collections until explicit approval.
- Mark the preview visibly as unpublished and set `noindex`.
- Regenerate from the canonical source after every substantive change.
- Verify locally, replace the intended preview deliberately, then open the returned public URL.
- Never treat preview approval as permission to commit, merge, deploy, or publish production content.

## Reference

- `references/relay-optimiser-example.md` — compact source/history/test audit showing how to separate relay rules from historical and current code.

## Checklist

- [ ] Rules, implementation, tests, and history were inspected where relevant.
- [ ] Domain rules, historical code, and current internals are not conflated.
- [ ] Product labels and order constraints are exact.
- [ ] Scope of exactness and any benchmark claim is qualified.
- [ ] Focused tests passed.
- [ ] The rendered review draft was checked after the correction.
