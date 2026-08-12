---
name: marketing-search-intelligence
description: "Use when working on marketing strategy, SEO/AIO/search visibility, competitive intelligence, analytics synthesis, personas, or AI-assisted marketing research. General go-to marketing intelligence skill; do not load for ordinary implementation work."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Marketing Search Intelligence

## Sources

- Obsidian summary: `/home/semyon/obsidian/personal/WebExpo 2026/Summaries/Marketing Search and Intelligence Summary.md`
- `39082775 - From SEO to AIO`
- `39082746 - Building an agentic competitive intelligence program`
- `39082748 - Reducing analytics noise with AI`
- `39082731 - Plausible is not valid`
- `39082727 - Don’t trust the bot`

## Core frame

Marketing visibility is becoming search + answer engines + social proof + citations + clear product entities. The useful work is reducing noise and producing decisions.

## SEO/AIO content structure

For pages that should be discoverable and citable, make these explicit:

- what it is;
- who it is for;
- problem solved;
- how it works;
- pricing or pricing logic;
- alternatives/comparisons;
- constraints / who it is not for;
- FAQs in normal language;
- evidence: screenshots, docs, changelog, case study, metrics.

Answer engines punish mush. Say the useful thing plainly.

## Competitive intelligence loop

Track competitors only where it can affect a decision:

- positioning changes;
- pricing/package changes;
- feature launches;
- docs/changelog activity;
- customer complaints;
- jobs signalling priorities;
- partnerships/integrations;
- social/media mentions.

Then convert to one of:

- roadmap decision;
- sales objection response;
- positioning update;
- content/comparison page;
- pricing/package adjustment;
- ignore.

## Analytics: reduce noise

Vanity metrics are not forbidden, but they are weak alone:

- page views;
- impressions;
- follower counts;
- email opens;
- time on site without intent.

Prefer:

- activation rate;
- qualified lead source;
- conversion by segment;
- funnel drop-off by step;
- retained usage after first value;
- support/contact themes;
- revenue by package/segment.

Use AI for clustering and anomaly surfacing, but keep source trails.

## Privacy-first navigation analytics

When a product needs to understand **general paths** without building person-level trails, instrument an aggregate transition graph rather than assigning a browser/session identifier.

Capture one event per meaningful public navigation choice with a strict allowlisted schema:

- `from_path` and `to_path`: pathname only; strip query strings and fragments.
- `placement`: fixed labels such as `header`, `footer`, `hero`, `content`, or `cta`.
- `action` / CTA label: a fixed allowlist, never arbitrary button text.
- acquisition on the first pageview: server-derived `direct` or `external`; retain only an external referrer origin when needed.
- timestamp: server receipt time.

This supports reports such as `landing → pricing via header`, `blog → contact via footer`, and CTA frequency over time. It does **not** claim a precise individual funnel or persist a visitor journey across reloads.

Do not add cookies, local/session storage, replay, raw URLs, query data, invite codes, email addresses, or a cross-app identifier merely to build path reports. Respect DNT/GPC client- and server-side. For authenticated product milestones, a per-app HMAC pseudonym may be appropriate, but never join it to anonymous acquisition records.

For a central view, keep collection and raw retention inside each app. Feed Grafana/Metabase aggregate daily/path/CTA tables only; do not centralize raw events or create a shared person key.

## Personas: plausible is not valid

A persona must cite evidence. Otherwise it is fan fiction with a job title.

Include:

- source references;
- confidence level;
- observed behaviors;
- jobs-to-be-done;
- buying triggers;
- objections;
- discovery channels;
- actual phrases/language.

## Output checklist

- [ ] Separate facts, inferences, and recommendations.
- [ ] Link every major claim to evidence.
- [ ] State what decision this should change.
- [ ] Avoid overfitting to AI-generated plausible patterns.
- [ ] Prefer fewer, stronger metrics.
