---
name: productivity
description: "Use when working with notes, docs, email, calendars, tasks, PDFs, meeting pipelines, or other office-style workspace tools."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# Productivity Workspace

## Overview

Use this skill for day-to-day knowledge work: notes, documents, email, calendars, task trackers, PDFs, meeting artifacts, and office-style collaboration tools. This umbrella turns a pile of narrow app-specific helpers into a single workflow-oriented guide.

The common pattern is: find the source of truth, make the smallest durable change, and verify the result in the app or exported artifact that the user actually consumes.

## When to Use

- The user asks you to manage notes, docs, reminders, email, or calendar content
- You need to inspect or transform PDFs and documents
- You are updating office-style artifacts like slides, meeting summaries, or workspace records
- The task is about a personal or team productivity app rather than a codebase

## Core Families

### Notes and knowledge bases
Use these when the user wants stored information, lightweight PKM, or a place to organize ideas:

- Apple Notes
- Notion
- Obsidian

When adding conference/workshop notes to Semyon's Obsidian vault, organize by event identity rather than topic overlap. Use a class-level structure such as `personal/Conferences/<Event>/`; keep Portershed, WebExpo, FOSDEM, and other events as siblings even when their talks cover the same funnel/product topic. Cross-link related notes across event folders and maintain `personal/Conferences/Index.md`. Do not place a new event's note inside another conference merely because that folder already contains related material. After moving an event directory, update explicit path links, Dataview folder filters, and home/index links, then search for stale old paths.

For Obsidian vault export/package/delivery tasks, see `references/obsidian-vault-export-delivery.md`. Key rule: verify archive contents and state exactly whether the bundle contains notes only or also transcripts/media.

For turning shared Google Docs into durable Obsidian notes and sending the Markdown back, see `references/google-doc-to-obsidian-handoff.md`: use the Google Docs `export?format=txt` path when possible, re-fetch full text if extraction truncates, stage only the intended note, leave unrelated vault changes alone, and attach the `.md` with `MEDIA:`.

For comparing a current/local event against Semyon's prior conference notes or transcripts, search the relevant Obsidian vault first, read the strongest matching note, then give a blunt attend/skip/networking verdict. See `references/conference-notes-event-comparison.md`.

For turning talk/workshop slides into a durable Obsidian follow-up note, see `references/talk-slides-to-obsidian-followup.md`: export public Google Slides as text where possible, search the vault for related conference/project context, place the synthesis beside existing related notes, update the local index, and keep the note project-specific and actionable rather than a generic talk recap.

### Tasks, reminders, scheduling, and event registration
Use these when the goal is a queue of follow-up items, timed nudges, calendar-like work, or signing the user up for events:

- Apple Reminders
- Calendar-backed workflows through Google Workspace
- meeting pipelines that turn calls into summaries or follow-up items
- Public event registration / booking forms: use the user's known identity details when already available, prefer a service-specific plus-address for filtering when the user asks for it, handle optional sensitive demographics conservatively, and report exact event names, times, email used, and confirmation numbers. Verify the final confirmation page; a filled form is not a completed booking. See `references/public-event-registration-forms.md`.

Browser-form pitfall: cookie overlays and Angular/Material radio groups can make normal clicks look successful without submitting. Dismiss cookie notices, inspect required fields with browser_console when stuck, set hidden backing inputs only when the visible radio state is not enough, and verify by reaching a confirmation/thank-you page rather than trusting a button click.

### Email and message surfaces
Use these when the work lives in mail or chat rather than a document:

- Candidate/interview emails and attachments: see `references/candidate-interview-document-workflow.md`. Extract NDAs/JDs/brochures yourself, parse MIME parts before assuming attachments exist, and draft replies in Semyon's natural concise voice rather than generic AI-polished recruiter prose.
- Early-career technical applications: verify the **exact live requisition** before advising on start dates, salary, eligibility, or a recruiter reply; title year and rolling/all-season intake can conflict with a candidate's placement window. Treat every screening checkbox literally: distinguish must-have from preferred criteria, map each claim to a concrete course/project example, and never inflate coursework (for example Big-O/calculus) into specialist experience such as linear/nonlinear optimisation. A personal project with separately deployed frontend/API, database, workers/queues, and storage can honestly evidence multi-tier/distributed-systems exposure; phrase it at its actual scale rather than claiming hyperscale production experience. For salary expectations, research the employer/location/role specifically, prefer a current annual/monthly figure the form requests, and label older self-reported compensation data as a benchmark rather than an official rate.
- Himalaya for mail operations
- iMessage-style personal messaging workflows
- Google Workspace/domain email audits via GAM plus DNS checks. See `references/google-workspace-email-audit.md` for the checklist and GAM command patterns.
- GAM profile setup for Workspace mail/admin access. Treat `gam.cfg` sections like AWS CLI profiles (`gam select <section> ...`), and see `references/gam-workspace-profiles.md` for profile, service-account, and domain-wide-delegation setup. Do not create fake GAM profiles for consumer `@gmail.com` accounts; use IMAP/SMTP app passwords or Gmail API OAuth for those.
- Google Workspace/GAM profile setup. When the user asks for AWS-CLI-like profiles or says “make GAM work here,” use GAM `gam.cfg` sections and `gam select <section>` first. See `references/google-workspace-gam-profiles.md`.
- GAM profile-style Workspace administration. When the user asks for AWS-CLI-like profiles, use GAM `gam.cfg` sections / `gam select <section>` first; see `references/gam-profiles-workspace-email.md`.
- Personal Google assistant workflows use the dedicated Hermes skills and local OAuth helpers first: `personal-google-apis` for account/OAuth context, `personal-gmail` for Gmail, `personal-google-data` for Calendar/Contacts/Drive metadata, and `personal-youtube-analytics` for YouTube/FoxScope stats and analytics. Do not default to Claude.ai Gmail MCP for Semyon's personal Google tasks; treat it only as an explicitly requested fallback.
- Private message-thread benchmark data sourcing: when Semyon wants to evaluate AI failures on pasted/screenshot WhatsApp, Discord, or email threads, prefer export-first, sanitized derived cases, objective labels, and privacy-safe raw-export handling. See `references/private-message-threadbench-data-sourcing.md`.

### Documents, slide-style artifacts, and interview prep
Use these when the user wants authored, edited, or transformed office files, or practical interview preparation:

- Google Workspace docs/sheets/slides
- PowerPoint decks
- PDF cleanup or text correction
- OCR / document extraction
- Interview preparation from CVs, role docs, or handoff notes

#### Targeted technical CVs
For an SDE/internship CV review or tailoring pass, inspect the submitted PDF **and** locate the canonical CV source/repo before recommending an upload. Extract PDF text with a layout-preserving tool and visually inspect rendered pages; generated LinkedIn PDFs often have poor hierarchy, generic summaries, and no useful project evidence even when their text looks acceptable.

- Compare variants on evidence, clarity, company-specific leakage, and layout. A company-specific CV must never be reused for another application with the original employer named in its header or availability line.
- For a student SDE role, prefer a **single page** when the candidate has enough real content to support it. Do not force it by shrinking typography or cramming every project in: remove redundant projects, generic awards, or lower-relevance leadership detail first.
- Tailor only with defensible evidence from the candidate's actual projects and the job description. Surface the role's real assessment terms (for example data structures/algorithms, OOP, databases, networking, async work, cloud, operational ownership) through modules, skills, and concrete project bullets; do not turn generic calculus or beginner familiarity into a claimed qualification.
- Project bullets should make the system shape legible: frontend/API, relational data, queues/workers, storage, retries/failure handling, deployment, tests, or monitoring — but distinguish a student multi-tier system from claimed large-scale production ownership.
- Keep company/role targeting human and restrained. A direct title such as “distributed systems, cloud infrastructure, and reliable services” is useful; keyword stuffing or copying the job ad is not.
- Compile the new PDF and verify: exactly one page, no overfull/underfull layout warnings, clean `pdftotext`/ATS extraction, and a rendered visual check for tiny type, clipping, crowded sections, and excessive unused page space. A portable user-local Tectonic build is a valid fallback when the normal LaTeX toolchain is absent.
- If the page is visibly cramped, rebuild it with measured line/section/list spacing and, if possible, a more readable base size. If a larger size creates a second page, cut lower-priority material rather than pretending a two-page spill is acceptable. Conversely, use available whitespace for readability rather than leaving a dense block at the top and a blank lower third.

### CV / résumé tailoring for technical internships

When preparing a CV for a named technical internship, first inspect the candidate’s existing source materials and every candidate PDF: extract text, render representative pages, and compare content **and** visual density before recommending a version. Do not mistake a LinkedIn-generated export for a suitable engineering CV: tell-tale signs include `First Name`/`Last Name` fields, “generated from LinkedIn” boilerplate, long generic summaries, and missing projects/skills.

- Keep a generic baseline CV and create a separate role-targeted source/PDF; never upload a version that names a different employer in its heading or availability line.
- For students, prefer one page only when it remains easy to scan. Do not win the one-page constraint by shrinking text or squeezing section spacing. If there is unused lower-page space, first increase readable line/section spacing and only then decide whether a concise interests line adds personality.
- Tailor to demonstrated evidence, not buzzwords: surface the relevant languages, CS fundamentals, data/queue/worker/service boundaries, deployment/reliability work, and concrete project outcomes only when the candidate can explain them in interview.
- Keep technical interests out of an interests line when they are already proven elsewhere in the CV. Use short, genuine, non-technical interests that make the candidate memorable without stealing space from evidence.
- Verify every final PDF as the user consumes it: exactly one page if intended, no overfull/clipped layout, clean `pdftotext`/ATS extraction, and a visual page review. A user-local Tectonic binary is a viable no-sudo fallback for compiling LaTeX CVs; use it, then run both text and visual checks.

For live interview coaching with Semyon, keep the interaction short and iterative: one question or answer at a time, polish his rough answer without dumping a full guide, and quiz him back immediately. If he says an answer is generic, replace it with his real context and phrasing rather than “professional” slop. For “should I ask X?” interview questions, give a direct yes/no plus the exact phrasing to use and the phrasing to avoid.

For a live technical-internship ATS application, use `references/technical-internship-application-triage.md`: answer eligibility and accommodation prompts precisely, map checkbox claims to defensible project evidence, and inspect any generated résumé before it is uploaded.

### Graduate / internship application forms

Treat each field as an assertion the applicant may later need to honour or explain. Give the exact selection first, then only the caveat that materially changes it. Never inflate availability, technical experience, relocation willingness, salary history, or immigration status to fit a requisition; a title year or generic form template does not override the applicant’s real placement window. Distinguish **application accommodations** (a change to the hiring process) from ordinary relocation/travel logistics. Generic EMEA forms may ask for several preferences while exposing only one dropdown; select the single truthful available preference and use a later city/free-text field if present rather than inventing rankings. For eligibility/compliance questions, do not infer a personal fact that has not been established: state the likely selection conditionally and flag the one fact the applicant must personally confirm. For project-experience screening, translate the candidate’s actual architecture into defensible language (for example web/API/database = multi-tier; separately deployed app, worker, queue and stores = distributed components) but do not turn broad CS knowledge such as Big-O or ordinary calculus into claims of operations-research optimisation experience.

### Structured records and simple databases
Use these when the user wants rows, records, or lightweight business objects:

- Airtable

### Academic module choices and head-start planning
Use this when Semyon is selecting university options or preparing for a compressed academic year. Reconstruct required/optional credit arithmetic from the current official curriculum, identify semester concentration and placement effects, then compare options using technical payoff, current assessment risk, project overlap, prerequisite fit, and prior-note coverage. Search the Obsidian vault for read-only prior-student material without editing it; inspect representative notes rather than relying on file counts. Treat a personal `Subject Choices` note as a decision record, not canonical curriculum evidence: verify current official module records and the cohort-specific handbook/Canvas details before presenting credits, assessments or availability as final. Historical projects and papers can establish likely skill/assessment surface, but never guarantee the next CA brief. Keep recommendations provisional until current assessments, prerequisites, timetable clashes, and actual module availability are verified. See `references/academic-module-choice-and-head-start.md` and the University of Galway candidate-module evidence bank at `references/galway-csit-year-3-option-evidence.md`.

### LMS / student portal results
Use this when Semyon asks for Canvas/LMS grades, module results, CA/exam breakdowns, honours estimates, or to reconcile “I know this material” with unexpectedly low official marks. Prefer the canonical API/integration over browser scraping, pull assignments + assignment groups + announcements + module PDFs/files where available, distinguish visible finals from inferred calculations, and set a short-lived silent watcher when results are expected to change today. Give Semyon a blunt forensic read: official result, visible CA, weights, implied exam/final component, likely failure mode (rubric mismatch, brittle tooling, rote recall, time pressure, or genuine weak foundation), and whether it is worth querying via consultation/recheck. See `references/lms-grade-monitoring.md`.

For deeper post-results analysis, use `references/academic-results-breakdown-analysis.md`: confirm assessment weights from source documents, reverse-engineer exam marks from CA/final where valid, separate official facts from inferred values, and flag consultation/recheck targets when CA/practical evidence and final marks diverge.

For University of Galway Digitary/Parchment access problems or official transcript / University Skills Passport PDFs, use `references/university-galway-digitary-results-documents.md`: separate live results from official transcript documents, troubleshoot SAML/browser privacy-shield failures without overgeneralizing, extract uploaded PDFs yourself with layout-preserving tools, and report the blunt classification + sore-thumb modules first.

When Semyon asks whether a mark “feels wrong” or wants an academic profile, compare official portal finals against Canvas-visible CA/submission evidence rather than just restating the final grades. Separate official marks, visible CA, explicit Canvas provisional/overall items, and inferred exam/hidden-component estimates. See `references/canvas-ca-vs-official-results-analysis.md`.

## Practical Workflow

1. Identify the canonical source of truth.
2. Decide whether the task is creation, update, extraction, or verification.
3. Use the narrowest tool or app surface that can make the change durable.
4. Verify the artifact in the destination format the user will actually read.
5. Preserve anything generated in a reusable form when appropriate.

## Tool Choice Hints

- Use Airtable when the problem is record-driven and row-shaped.
- Use Apple Notes, Notion, or Obsidian when the problem is human-readable knowledge capture.
- Use Google Workspace when the file must live in shared docs, sheets, or slides.
- Use OCR/document extraction before editing scanned or image-based PDFs.
- Use meeting pipeline helpers when the request is about turning calls into actionable output.

## Technical personal-blog drafting

When editing a portfolio post that needs to be both personal and informative, build **one guided tour**, not a personal story followed by a detached documentation appendix. Begin with a concise personal premise and a compact at-a-glance block, then use outcome-led sections that introduce technical mechanisms only when they explain a concrete use.

- Lead with the outcome, then explain the mechanism: “it gives me a morning status summary” before “I configured a scheduled job.”
- Treat headings as a skimmed summary: someone reading only headings should understand why it matters, what it does, how it is organised, its limits, and how to begin.
- Use bullets for orientation and constraints, a small table only for genuine comparisons, and code only where a reusable prompt/configuration is useful.
- Keep paragraphs short and avoid repeating a concept in both narrative and reference form. Link or move optional implementation detail rather than creating a long appendix by default.
- For Semyon’s technical portfolio writing, preserve a direct human voice and real constraints; avoid product-feature inventories and AI-marketing language.
- When a first revision is still too text-heavy, do not solve it by separating a short story from a dense appendix. Keep one guided tour, retain specific lived examples, and cut generic architecture/feature explanation before cutting the personal evidence.
- For a more personal second pass, audit the live system read-only first and explicitly separate custom choices from out-of-box defaults. Then ask open-ended questions rather than filling gaps from inference; map the answers to exact sections (origin moment, former workflow friction, recurring win, safety boundary, limitation, and closing advice). Do not publish secrets, private IDs, or infrastructure topology.
- Be precise about agency: distinguish the assistant framework’s workflow/access layer from the underlying model’s capability limits, and distinguish deterministic scripts from LLM-backed judgement.
- When Semyon iterates on a portfolio post, make a structural pass before line-polishing: fold his answers into the relevant section, cut duplicate explanation, and prefer replacing generic architecture prose over appending another explanatory block. Keep the core personal evidence (a real incident, a recurring win, an explicit safety boundary) but do not stack anecdotes.
- His preferred final prose is short, human, and direct: split long compound sentences; use plain verbs; let paragraphs carry one point; avoid polished product-copy phrasing such as feature inventories or abstract “assistant layer” language unless it is immediately explained.
- For agent-framework posts, distinguish the framework from the underlying model: the model reasons; the framework supplies workflow, tools, memory, messaging, scheduling, and guardrails. Do not imply that scheduled work necessarily uses an LLM when script-only jobs are part of the setup.
- Verify the final source using the project’s formatter, type/content checks, and static build before delivery. Attach the actual edited Markdown when he asks to review it in Discord.

## Pitfalls

- Editing the wrong app surface because the same content exists in multiple places
- Assuming a cloud note or doc is synced without verifying it
- Treating OCR text as final without checking layout or missing sections
- Changing a slide deck without confirming the deck format the user actually needs
- Forgetting that some apps are personal, some are shared, and some are both
- Splitting a technical personal post into a “quick story” and a dense appendix when the reader needs a coherent, progressively disclosed explanation instead
- Putting setup detail before the practical result it enables, or adding tables/callouts merely to decorate normal prose

## Verification Checklist

- [ ] Canonical source identified
- [ ] Correct app surface chosen
- [ ] Change persisted in the destination artifact
- [ ] Extracted or transformed content checked for completeness
- [ ] User-facing output matches the requested format
