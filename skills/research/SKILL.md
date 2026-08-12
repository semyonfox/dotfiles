---
name: research
description: "Use when finding, monitoring, extracting, or synthesizing external information from papers, feeds, knowledge bases, market data, webpages, or transcripts."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Research Workflow

## Overview

Use this skill when the task is about gathering information rather than acting on a local system: papers, blog monitoring, web extraction, transcript summaries, market signals, or knowledge-base synthesis. The goal is to identify reliable sources, extract the right facts, and turn them into a concise answer or reusable artifact.

This umbrella replaces a collection of narrow source-specific helpers with one source-driven research workflow.

## When to Use

- The user asks you to find, compare, or summarize information from external sources
- You need to monitor a feed or watch a content source over time
- You need to extract facts from pages, transcripts, or structured external data
- The task is synthesis or analysis rather than code execution

## Core Source Families

### Papers and academic material
Use these for literature review, paper discovery, and technical citation work.

- arXiv
- **University module / past-paper comparison:** search the user's local study vault, course repos, Downloads/Documents, synced archives, and backup copies before assuming a paper is absent. Search by module code in filenames **and** by PDF text because archives often use generic year/session filenames. Then check the university's official past-paper archive. If it requires institutional SSO, say so plainly and give the exact official route; do not use unauthenticated reposts or claim that two-paper comparisons were completed when papers were unavailable. Separate evidence into: (1) actual exam papers, (2) official assessment briefs, and (3) public student project artefacts. Historical student repos can establish likely project shape and workload, but must be labelled non-current and non-official. When advising module selection, weight assessment split, exam exposure, project scope risk, and the student's demonstrated skills separately.
- research-paper-writing workflows
- LLM multi-party chat/context benchmarks: when evaluating whether models understand who is speaking, who is addressed, reply links, quoted instructions, or group-chat state, ground the benchmark in addressee-recognition/dialogue-disentanglement work and build a runnable JSONL harness rather than only a narrative plan. See `references/llm-multiparty-chat-context-benchmarks.md`.

### Feeds and monitors
Use these for recurring discovery and change detection.

- blogwatcher-style feeds
- RSS-based daily briefings: start from a small, reliable source set; verify feed URLs return XML before wiring them into cron; deduplicate aggressively because wire services and major outlets repeat the same stories.
- When a user asks to keep a closer eye on a source/category that plausibly belongs to an existing briefing/radar cron, inspect existing cron jobs first and patch the relevant job instead of creating a parallel watchdog. Only create a separate monitor when the cadence, destination, or alert semantics genuinely differ.
- When a publisher has no stable public RSS feed, use a clearly labelled aggregator/search fallback rather than pretending it is first-party. Reuters, AP, and Ground News may need Google News RSS queries such as `https://news.google.com/rss/search?q=site%3Areuters.com&hl=en-IE&gl=IE&ceid=IE%3Aen`, `site%3Aapnews.com`, or `site%3Aground.news`. Treat those as supplemental/discovery feeds, not the factual backbone.

### Knowledge bases and retrieval
Use these when the user wants an indexed reference layer or connected notes.

- llm-wiki-style research knowledge bases

### Web extraction
Use these when the content lives on a public page and needs structured extraction rather than plain reading.

- public-web extraction
- AI coding-agent platform capability research: when comparing Codex/ChatGPT desktop/CLI/app/browser/computer-use support across Linux, Windows, and macOS, prioritize official OpenAI docs, separate surfaces explicitly, verify local CLI health with real commands, and label unofficial ports/workarounds clearly. See `references/codex-platform-capability-research.md`.
- Frontier AI model routing/pricing comparisons: when comparing GPT/Claude/Gemini-style model families, reasoning levels, prices, context windows, and practical balance points, prioritize official model docs and reasoning guides, compute representative costs with explicit token assumptions, and separate documented facts from heuristic routing judgement. See `references/frontier-ai-model-comparison.md`.
- Newspaper/e-reader code, coupon, stamp, and competition-page research: when normal web search misses print-only promotions, inspect e-reader replica assets/page images, build contact sheets, and report exact section/page/date/code rather than guessing. For Business Post e-reader specifics, see `references/business-post-ereader-code-promotions.md`.
- Phone-number OSINT for nuisance/wrong-number call floods: search exact and normalized number formats, hospitality/travel context terms, spam-report sites, and typo-near matches; absence from public search does not rule out private booking confirmations or app-only listings. See `references/phone-number-osint-nuisance-calls.md`.
- Phone-number OSINT for nuisance/wrong-number call floods: search exact and normalized number formats, hospitality/travel context terms, spam-report sites, and typo-near matches; absence from public search does not rule out private booking confirmations or app-only listings. See `references/phone-number-osint-nuisance-calls.md`.
- SpiderFoot OSINT tooling setup: for local automated OSINT setup, install SpiderFoot in an isolated venv, handle modern Python/PyYAML compatibility, wire no-key tools like dnstwist/wafw00f/snallygaster/retire.js, and keep API keys out of chat. See `references/spiderfoot-osint-tooling.md`.
- OSINT API account signup and key intake: unlock Vaultwarden first, create pending provider items with generated passwords and `API key=PENDING`, then only configure SpiderFoot after a confirmed key exists; CAPTCHA/Arkose blocks are common and should be reported as signup blockers, not as completed setup. See `references/osint-api-account-signup.md`.
- Irish LTD/company compliance research: use official Revenue/CRO/RBO pages first, quote exact wording for challenged legal/tax claims, and consult `references/irish-ltd-compliance-research.md` for source-priority and answer-shape notes.
- AI/GDPR compliance audits for EU/Ireland SaaS: inspect the code paths that send user content to LLM/embedding/rerank/OCR providers, verify provider DPA/SCC/ZDR/training/retention posture, and check privacy/deletion/export implementation before giving a launch verdict. See `references/ai-gdpr-compliance-audit.md` for the audit checklist and answer shape.
- Private conversation-context benchmarks: when evaluating LLMs on pasted/screenshot Discord or WhatsApp threads — especially “here is the thread, how do I reply?” — use public multi-party dialogue/disentanglement datasets only for taxonomy, then build a private sanitized eval set with labels for last real speaker, who-said-what, reply link, current reply intent, authority boundary, and ambiguity. See `references/private-conversation-benchmark-data.md`.

### Market and signal research
Use these when the question is about prices, probabilities, or externally observed signal data.

- Job/internship opportunity hunts: split broad searches by region/market (e.g. France/EU, Ireland/UK, US/Canada) and role family, especially when timing constraints are strict. Treat the user's stated placement window as a hard eligibility filter, not a preference: a summer-only 10–12 week role is **not** an actionable result for a January–August placement. Return two tiers: **open actionable postings** and **watchlist/speculative targets**. For each opportunity include company, role, URL, location/remote, start/duration if stated, open vs watchlist status, fit rationale, visa/language caveats, and next action. Keep timing-mismatched roles out of the actionable tier; mention them only if they establish a useful employer pattern (for example, a company already offers 4–8 month internships and visa support), then state the mismatch first and give a concrete outreach route. For international internships, surface visa/work-authorisation caveats early (e.g. US J-1 Intern via third-party sponsor, Canada IEC possibilities) before the user sinks time into applications. For a US student outside the US, distinguish a company’s generic future-work visa/H-1B policy from its willingness to host a J-1 Intern; verify or explicitly ask about the latter.
- Polymarket
- Flight fare comparison workflows and live route-price extraction. See `references/flight-fare-comparison.md`.
- Event travel budgeting: verify official event admission/credits, price flights from preferred/fallback airports, accommodation, food/transit, and sightseeing-day padding separately. See `references/event-travel-budgeting.md`.
- Broad conference-trip shortlisting: when the user asks for "any conferences" within a budget, discover multiple events first, then rank by all-in feasibility and entrance cost rather than prestige. See `references/conference-trip-shortlisting.md`.
- Local venue/community event monitoring: when a nearby venue or organiser is high-value to the user, first inspect existing recurring event/news radar jobs and update the relevant one if the user means “include this source too”; only create a separate script-only watchdog when a distinct alerting cadence is genuinely needed. For official pages plus organiser listings, keep reports low-noise: surface events with clear tech, startup, career, networking, infrastructure, or strong personal-interest value, and avoid generic filler. See `references/local-event-watchdog-monitoring.md`.
- Repo-based product pricing and salary-replacement analysis: when the user asks whether a local product can match a job/salary or hit a revenue target, read the repo's pricing/unit-economics docs first, separate gross MRR from net contribution/payroll-safe targets, and compute tier/blended subscriber counts with a tool. See `references/repo-pricing-business-analysis.md`.
- Repo AI/LMS compliance audits: when asked whether an app's AI, Canvas/LMS, GDPR, EU-law, or data-processing integration is compliant, inspect the actual code/data flows first, then cross-check official regulator/provider docs and user-facing policies. See `references/repo-ai-lms-compliance-audit.md`.

### Transcript and content research
Use these when the source is a video or transcript and the output should be summary, thread, or article-level synthesis.

4. Recommendations should distinguish a brand's flagship/bestseller from objectively "best": frame a flagship as the safest all-round pick, and note that rare or limited lots may be more adventurous rather than categorically better. For unfamiliar beans, recommend a smaller bag before a kilogram unless the buyer already knows the coffee.
5. **Refurbished-phone shopping:** establish the buyer’s current handset, hard budget, screen-size/storage/charging expectations, and whether “no downgrade” means raw performance, battery, camera, or software support *before* ranking deals. Compare every candidate directly against that baseline, not against launch-price discounts or generic mid-range phones. A cheap old flagship may retain performance but lose on update support and battery; a newer mid-range can be a performance downgrade despite attractive camera/RAM numbers. If no listing meets both the stated budget and no-downgrade constraint, say so plainly and identify the first price point where it does rather than quietly relaxing either constraint.

## Practical Workflow

1. Define the exact question or hypothesis.

When a user asks what a shop currently sells (especially coffee, food, or other variant products):

1. Start from the shop’s own category/catalogue page to establish the current product set and listed headline prices.
2. Open each relevant product page: category cards often hide variant-specific pack sizes, prices, and sale status.
3. Separate the requested format (for example, **whole beans**) from capsules, sachets, accessories, and products marked not sold individually.
4. Report pack weights and prices exactly as listed. Do **not** call a variant “in stock” or give an inventory count unless the shop exposes that information; “Add to cart” and a selectable variant only establish that it is offered online at the time checked.
## Commerce and product-catalogue research

When a user asks what a shop currently sells, especially coffee, food, gear, or subscription products:

### Replacement-tech shopping: establish the floor before recommending

For phones, laptops, or other replacement devices, do not begin by equating the cheapest listing with the best deal. First establish the existing device and **hard requirements** (for example: minimum charging speed, storage, display size/refresh rate, camera, repairability, budget ceiling, and support horizon). Treat these as filters, not nice-to-haves.

- Compare shortlisted devices against the current device in separate dimensions: raw CPU/GPU performance, storage/RAM, display, battery, charging, camera, software/security support, condition, and warranty.
- Label every compromise explicitly. A newer mid-range device may have a better camera or longer support but still be a downgrade in performance, display, charging, or storage.
- If the buyer says a feature is non-negotiable, immediately remove all non-matching options and re-rank; do not continue suggesting them as "sensible" alternatives.
- When the requested budget cannot buy a genuine non-downgrade, say so plainly and give the nearest valid listing plus the minimum budget that clears the constraint. Do not manufacture a false bargain.
- For refurbished listings, verify the *selected* configuration, cosmetic grade, stock state, return period, warranty, included charger/cable, and whether the advertised charging standard requires a proprietary in-box charger.


1. Treat **catalogue presence**, **purchasable availability**, and **physical stock quantity** as separate facts. A product page can prove available pack sizes and prices but normally cannot prove how many units remain; say that plainly rather than implying an inventory count.
2. Inspect each product page for variant sizes, current price, origin/style, and add-to-cart state. Exclude capsules, samplers, and non-individually-sold collaboration items unless the user asks for them.
3. For prices in another currency, prefer the seller's own currency/channel when it is accessible. If conversion is needed, use a current authoritative reference rate, label it an estimate, and use a calculation tool rather than mental arithmetic.
4. Do not promise a direct checkout URL if the shop uses a POST-only add-to-cart form. Give the exact product page and the few user-visible steps (choose variant, add to cart, checkout).
5. Recommendations should distinguish a brand's flagship/bestseller from objectively "best": frame a flagship as the safest all-round pick, and note that rare or limited lots may be more adventurous rather than categorically better. For unfamiliar beans, recommend a smaller bag before a kilogram unless the buyer already knows the coffee.
4. Recommendations should distinguish a brand's flagship/bestseller from objectively "best": frame a flagship as the safest all-round pick, and note that rare or limited lots may be more adventurous rather than categorically better. For unfamiliar beans, recommend a smaller bag before a kilogram unless the buyer already knows the coffee.
5. **Refurbished-phone shopping:** establish the buyer’s current handset, hard budget, screen-size/storage/charging expectations, and whether “no downgrade” means raw performance, battery, camera, or software support *before* ranking deals. Compare every candidate directly against that baseline, not against launch-price discounts or generic mid-range phones. A cheap old flagship may retain performance but lose on update support and battery; a newer mid-range can be a performance downgrade despite attractive camera/RAM numbers. If no listing meets both the stated budget and no-downgrade constraint, say so plainly and identify the first price point where it does rather than quietly relaxing either constraint.

## Practical Workflow

1. Define the exact question or hypothesis.
2. Identify the source family that best answers it.
3. Extract the minimum set of facts needed to support the answer.
4. Cross-check obvious contradictions or missing context.
5. Summarize with the level of confidence the evidence supports.

## Tool Choice Hints

- Use a monitor or feed skill when the question is "what changed since last time?"
- Use web extraction when the important data is embedded in a page rather than in the headline.
- Use transcript workflows when the important facts are spoken rather than written.
- Use knowledge-base workflows when the task is not one source but a connected body of material.

## Pitfalls

- Trusting one source when the topic clearly has competing views or stale pages
- Mixing extraction and interpretation without separating evidence from conclusion
- Answering from memory when the user asked for current or source-backed information
- For early product/API ideas, over-expanding the user's narrow primitive into a full product stack too quickly. First distinguish: what already exists, what exact part remains unsolved, whether the user's simplified framing is still novel, and only then suggest implementation/adoption paths.
- Over-summarizing a transcript or paper and losing the important caveats
- Overfeeding a daily briefing cron with too many feeds. More sources can reduce quality if the task becomes duplicate-filtering instead of news selection; prefer a compact curated set plus explicit deduplication/source-priority rules.
- Treating Google News RSS, RSS.app, Feedspot, or similar generated feeds as official publisher feeds. Label aggregator fallbacks clearly and prefer direct XML feeds where available.
- For public-transport timings, establish the origin, destination, date, and latest acceptable arrival before searching. Prefer the operator’s own journey planner or timetable PDF; use third-party timetable sites only as a cross-check. State the recommended service with a realistic walking/delay buffer, and advise a live check on the day for disruption notices.

## Verification Checklist

- [ ] Source family identified
- [ ] Evidence extracted from the right place
- [ ] Conflicts or stale data considered
- [ ] Conclusion matches the evidence quality
- [ ] Output is in the format the user asked for
