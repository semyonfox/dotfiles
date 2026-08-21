---
name: agent-friendly-sites
description: Audit, design, or implement websites that are friendly to user-delegated AI agents while staying spam-safe. Use when the task mentions AI-friendly sites, agent accessibility, llms.txt, machine-readable discovery, OpenAPI/action endpoints, structured data, robots rules for AI crawlers, contact forms for agents, or making a site usable by assistants without exposing raw email or unsafe state-changing actions.

metadata:
  harness: [claude, codex, opencode, cursor]
---

# Agent-Friendly Sites

## Core Principle

Design for two different agent jobs:

- Read-only discovery: let agents find canonical facts, pages, docs, and APIs cheaply.
- State-changing actions: let agents act only through explicit, rate-limited, validated flows that preserve user intent.

Do not treat "agent friendly" as "scraper friendly". Public content can be easy to parse; actions still need friction, verification, and abuse controls.

## Workflow

1. Identify the site goal and action surface.
   - For portfolios, prioritize: understand the person, inspect work, download CV, ask the site assistant, and contact the owner.
   - Classify every action as read-only, low-risk intent capture, or high-risk state change.

2. Audit existing discovery.
   - Check `robots.txt`, sitemap, canonical links, Markdown variants, `llms.txt`, JSON-LD, Open Graph, API catalog, OpenAPI, and human-readable docs.
   - Verify Markdown uses `text/markdown; charset=utf-8`; APIs use `application/json`.
   - If crawler names or vendor AI policies matter, browse current official docs before recommending exact rules.

3. Audit action safety.
   - Look for raw email exposure, `mailto:` as the only contact path, third-party form-only flows, missing labels, missing honeypots, permissive CORS, missing rate limits, weak request schemas, and unclear privacy behavior.
   - Prefer a documented contact intent endpoint over direct email exposure.

4. Recommend the smallest useful architecture.
   - Keep static content simple: `/llms.txt`, Markdown page variants, sitemap, JSON-LD, and canonical HTML.
   - Keep actions explicit: `/api/contact-intents`, OpenAPI, accessible HTML form fallback, idempotency, sender verification, moderation, and rate limits.
   - Keep raw private routing hidden: do not publish a direct email address in machine-readable docs unless the owner explicitly accepts harvesting risk.

5. Validate with both agent paths.
   - Browser path: a user-delegated browser agent can find and submit the semantic HTML form.
   - API path: a tool-using agent can discover the OpenAPI spec, submit a valid JSON payload, and explain the verification step to the user.

## Deliverable Shape

When producing an audit or plan, include:

- Current state: what already helps agents.
- Gaps: what blocks agents or increases spam risk.
- Recommended design: discovery, actions, spam controls, and privacy.
- Implementation phases: docs-only quick wins first, backend action endpoints second.
- Acceptance tests: exact checks for content types, discovery files, schemas, form behavior, rate limits, and verification flow.

## Reference

Read `references/patterns.md` when drafting concrete examples, snippets, endpoint schemas, robots policies, or implementation checklists.
