---
name: saas-funnel-growth
description: "Use when diagnosing SaaS/product funnels, activation, conversion, retention, lead magnets, PMF leaks, or growth experiments. General go-to funnel/growth skill; do not load for unrelated marketing copy or UI tasks."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# SaaS Funnel Growth

## Sources

- Obsidian summary: `/home/semyon/obsidian/personal/WebExpo 2026/Summaries/SaaS Funnel and Growth Summary.md`
- `39082768 - Fixing a broken SaaS funnel`
- `39082771 - Hourglass analysis`
- `39082770 - Building the engine that drives better product decisions`
- `39082680 - Stop building on hope`

## Core frame

A funnel is where discovery, comprehension, trust, activation, payment, and retention connect or leak. Diagnose with actual journey data, not vibes or vanity metrics.

## Data to pull

- Website analytics.
- CRM.
- Stripe/back-office/payment platform.
- Product usage events.
- Customer success notes.
- Sales call notes.
- Churn/refund reasons.
- Support/contact themes.

## Leak categories

- **Awareness leak:** right people never encounter the product.
- **Comprehension leak:** visitors do not understand why it matters.
- **Trust leak:** they understand but do not believe.
- **Activation leak:** they try but fail to reach first value.
- **PMF leak:** the segment does not care enough; marketing cannot perfume this for long.

## Diagnostic workflow

1. Define one target segment and one funnel.
2. Map stages from discovery to repeat value.
3. Attach numbers and qualitative evidence to each stage.
4. Identify the largest leak.
5. Decide whether it is marketing, onboarding, product, pricing, or PMF.
6. Ship one intervention.
7. Measure activation/conversion/retention impact.

## Soft CTAs

Use when buyers are not ready for sales/demo yet:

- checklist;
- template;
- calculator;
- demo dataset;
- teardown/audit;
- “send me the example” email capture;
- waitlist with a clear promise.

Soft CTA must educate or move intent forward, not just feed a CRM graveyard.

## Hourglass analysis

Combine:

- **Top-down:** explicit business/product questions and hypotheses.
- **Bottom-up:** raw user/customer data and emergent themes.

AI can cluster and summarize, but keep raw examples attached.

## Privacy-first analytics implementation

For multi-app analytics architecture, provider selection, live browser-storage checks, server-canonical events, central aggregate dashboards, and draft-PR verification, use `references/privacy-first-product-analytics.md`.

When reporting an analytics implementation to Semyon, lead with a compact verdict: what is kept, what is removed, where aggregate reporting lives, verification results, and PR links. Avoid a file-by-file firehose unless requested.

## Review checklist

- [ ] One target segment, not everyone.
- [ ] Actual data from journey systems.
- [ ] Biggest leak identified.
- [ ] Marketing leak separated from PMF leak.
- [ ] First value is short and obvious.
- [ ] Soft CTA exists for not-ready buyers.
- [ ] Experiment has one intervention and one success metric.
