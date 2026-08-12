---
name: personal-productivity-workflows
description: "Use when personal productivity workflows for location lookups, public technical writing, and lightweight exploratory notebooks."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Personal Productivity Workflows

Use this class-level umbrella when the user asks for practical personal-output work that is not primarily codebase editing: location intelligence, concise public writing, or interactive exploratory analysis.

## Workflow families

### Interview coaching and demo prep

Use this when Semyon is preparing for an interview, onsite visit, project walkthrough, or technical demo. Default to a conversational coaching loop, not a giant one-shot briefing: keep answers short, ask one focused practice question at a time, let Semyon rough-answer in his own words, then tighten it. If he says the output is too much, immediately switch to concise back-and-forth mode.

For project-demo prep, separate **personal pride** from **role relevance**. Let Semyon lead with the project he genuinely cares about when asked “what are you proud of,” but steer the role-relevant walkthrough toward the project with the strongest evidence for the job. For SRE/platform interviews, frame stories around production constraints, debugging, queues/background work, observability, recovery, and lessons learned. Avoid generic corporate phrasing; preserve Semyon’s direct voice while removing landmines such as oversharing, tool-goblin details, or jokes that could read as reckless.

When coaching AI-tooling answers, present Semyon as AI-native but responsible: AI speeds up debugging, explanation, boilerplate, tradeoff review, and architecture thinking; it does not remove his responsibility to understand, review, test, and follow company data/tooling policy.

### Location intelligence, local venues, and bookings

Use this for practical local decisions: geocoding, POI search, cinema/showtime lookups, event booking recaps, venue comparisons, ticket-booking handoffs, distances, directions, public transport options, or timezone lookup. Prefer official venue sources for current availability and prices, using aggregators only as cross-checks. For online enquiry/appointment forms, verify the actual page/form before advising: separate **fields explicitly required by the form** from **sensible extra context that reduces back-and-forth**. Do not imply inferred items like referral letters, insurance, DOB, or medical history are required unless the form/site says so. If the user is only asking whether online booking is possible, report whether it is a live self-booking calendar or merely an enquiry form that triggers follow-up. For cinemas, see `references/cinema-showtimes-booking.md` for the preferred showtime/rating/booking-handoff workflow.

For local event recaps after a booking/sign-up, do **not** rely on memory alone. Reconstruct the booking from session history if needed, then verify the event details against the official venue/event page before giving Semyon a concise handoff: title, time, venue/address, booking reference if known, why it matters, and the best practical route. For Galway rail trips, use Athenry as Semyon’s default departure station unless he says otherwise. Check the official Irish Rail Journey Planner for the specific date and cross-check its published timetable when useful. Give both the latest technically viable service and the recommended service with a walking/delay buffer; do not treat an interview’s expected finish time as the right reminder time when travel preparation requires an earlier nudge. For booking, default to Semyon entering account credentials and payment details in his own browser. Never request, persist, log, script, or expose card details, CVV, 3-D Secure codes, password-manager contents, or browser-autofill data. **Narrow exception:** if Semyon explicitly authorises it and has already supplied an ephemeral Bitwarden CLI `BW_SESSION`, use it only for the single named booking-site login: verify `bw status`, identify the target vault item by metadata without dumping vault contents, retrieve only its login fields, fill the website's account-login form, then run `bw lock`, `unset BW_SESSION`, and verify the vault is locked. Never use the vault for payment cards or echo any credential/token in a reply. When Semyon explicitly asks to see how far the booking can be prepared, it is safe to search the journey, select the stated passenger type and fare, accept automatic seat allocation, skip optional extras, and continue through account login. Stop before **Review and Pay**: report the exact service, fare, availability/sold-out class, and that no payment was started. Obtain an explicit final confirmation immediately before any purchase. Semyon signs in and makes the final purchase in his own browser. Details and endpoints are in `references/local-event-booking-and-transit.md`.

### Location intelligence and maps

Use the bundled OpenStreetMap/OSRM/Nominatim client when the task is geocoding, reverse geocoding, POI search, distances, directions, or timezone lookup. Prefer the local script first because it has no API key requirement and emits user-facing map links.

Script path after consolidation:

```bash
MAPS="$HOME/.hermes/skills/productivity/personal-productivity-workflows/scripts/maps_client.py"
python3 "$MAPS" search "Eiffel Tower"
python3 "$MAPS" nearby --near "Times Square, New York" --category cafe --limit 5
python3 "$MAPS" distance "Paris" --to "Lyon" --mode driving
```

When a user sends a location pin, extract latitude/longitude and pass them directly to `nearby`. For “open now?” questions, treat OSM opening hours as useful but community-maintained; verify important venues with web search when recency matters.

### Cinema listings, ratings, and booking handoff

Use this when Semyon asks what films are on nearby, showtimes, age ratings, or help booking tickets. Prefer official cinema pages for current showtimes, then aggregator pages such as entertainment.ie to cross-check and summarize quickly. For Irish age ratings and reasons, use IFCO pages where possible; quote the rating rationale briefly rather than guessing from MPAA/BBFC.

For booking flows, gather the booking-critical choices before payment: cinema, date, showtime, number of tickets, ticket types, and seat preference. If the user asks for best seats, recommend 3 adjacent seats in the centre block, horizontally centred, about two-thirds back from the screen (sound/image sweet spot), avoiding the front third and very back row.

If the ticketing site uses Veezi/Cloudflare and blocks the browser session, do not overclaim that the booking is prepared. Extract the exact showtime booking link from the cinema page, tell Semyon the exact ticket mix and expected total from the cinema ticket-prices page, and hand over for payment. It is acceptable to click a visible Cloudflare verification control once when the user asks, but if it does not pass, stop and explain that the human should open the link on their own device. Never handle card details; assume online booking requires payment now unless the cinema explicitly offers “reserve/pay later”. Revolut usually works as a normal Visa/Mastercard; Google Pay/Apple Pay may appear only if the checkout exposes wallet payment on the user’s device/browser.

For local cinema / event-listing questions, check the current local date/time first, then verify showtimes against venue pages or reputable aggregators. Prefer primary venue pages when they expose clean data; use aggregators like entertainment.ie to cross-check and fill gaps. If the user names exclusions (“not the Michael Jackson one”), filter them out explicitly and lead with the best matching option, not a giant undifferentiated listing. For time-sensitive requests, note which showings are still realistically upcoming based on the current time.

### Interview preparation kits

Use this when Semyon asks for interview prep, interview handoff synthesis, mock questions/answers, role/company preparation, or practical career coaching for a specific interview. The preferred output is a small, usable prep kit under `~/interview-prep/<company-or-role>/`, not a giant chat dump: overall strategy, grounded STAR project answer, domain cheat sheet, mock interview answers, architecture/demo notes, and a last-minute drill card. Inspect relevant local projects/repos before writing project claims, verify any optional side project actually runs, and package the folder as an attachment when useful. Keep the tone direct, practical, confidence-building, and non-corporate; do not oversell expertise. Details and a reusable file layout are in `references/interview-prep-kits.md`.

### Interview and career prep coaching

Use this when Semyon asks for interview prep, role/company positioning, CV-to-answer mapping, mock questions, or career-event prep. Do **not** dump a full prep dossier up front unless explicitly asked. Run it as a normal conversation: short answers, one point at a time, then quiz Semyon with a likely interview question and tighten his rough answer. Preserve his natural voice while removing interview landmines, generic slop, overclaims, and jokes that are funny to us but risky in the room.

Workflow:

1. Start by identifying the 1–2 best stories/projects for the specific role, using CV/site/session context if available.
2. Give a concise recommended phrasing, not a giant script.
3. Ask Semyon to answer the next likely question in his own words.
4. Polish his wording while preserving the core personal truth.
5. Explicitly flag phrases to avoid when they could sound naïve, arrogant, AI-dependent, or too casual.

For technical interviews, favour concrete, role-aligned project stories over broad bragging. For SRE/backend/devops roles, strong answer themes include: production constraints, local-vs-prod differences, platform limits, queues/background jobs, progress tracking, timing logs/traces, observability, rollback, and reliability lessons. If Semyon mentions AI-assisted work, frame it as a learning/debugging aid whose output he reviews, understands, and verifies — never as “AI does it all.”

### Personal technical blog drafting

Use this when Semyon asks to draft, rewrite, tighten, or prepare a personal/technical blog post. Start with a publishable post, not an encyclopedia. Preserve Semyon’s voice: direct, practical, mildly funny, and not corporate. Respect privacy by default: do not publish secrets, `.env` values, internal IDs, phone numbers, private chat IDs, screenshots/logs with sensitive content, or exact persona/private names unless explicitly approved.

For Hermes/agent posts, keep the centre of gravity on lived workflow and practical examples. Avoid sales-pitch language. If diagrams are needed in Astro/Markdown posts, render Mermaid or diagrams to real web-safe assets, verify alpha/format/dimensions, and screenshot the rendered page at content width. Detailed diagram notes are in `references/mermaid-inline-diagrams.md`.

### Live Jupyter / notebook exploration

Use this when a task benefits from a stateful Python REPL instead of one-shot execution: iterative data exploration, DataFrame/API inspection, long notebook work, or building up variables across cells. Check prerequisites before depending on it:

```bash
command -v uv
SCRIPT="$HOME/.agent-skills/hamelnb/skills/jupyter-live-kernel/the local supporting file"
uv run "$SCRIPT" servers --compact
uv run "$SCRIPT" notebooks --compact
```

If no server is running, start JupyterLab headlessly and create a scratch notebook/session before executing code. Always use `--compact` to reduce output size. Retry once after first-execution timeouts because kernels can take a moment to initialize.

### Personal Google account, Gmail, and YouTube CLI access

Use this when Semyon asks whether Hermes can access personal Gmail/Google accounts, YouTube gaming channels, or YouTube Analytics from CLIs, cron jobs, or local tools. First check existing tool/credential state without exposing secrets: report installed binaries, credential file metadata, known accounts/scopes, and token expiry only. Distinguish Workspace admin tooling such as GAM from personal Gmail/YouTube access; a working Workspace admin token does not mean the personal Gmail or YouTube Analytics scopes are present.

For personal Gmail and normal YouTube channel analytics, prefer OAuth 2.0 desktop/installed-app auth with `access_type=offline` and one stored refresh token per Google identity. Do not recommend service accounts for personal YouTube/private analytics; YouTube Data/Analytics/Reporting APIs do not support service-account access to user/channel-private data, and Gmail service-account impersonation is a Workspace domain-wide delegation pattern rather than a personal Gmail pattern. Start with read-only scopes, save tokens under `~/.hermes/google-personal/accounts/<label>/token.json` with mode `600`, and verify with harmless read-only probes before creating cron jobs or write-capable tools. See `references/personal-google-oauth-cli.md` for the full setup, scopes, verification probes, and common error meanings.

### Contact/email lookups from prior Hermes sessions

Use this when Semyon asks for someone’s email/address/contact and the clue may be in a prior Hermes conversation. Start with `session_search` using the person name plus likely organization/context, then inspect the relevant session window. Treat copied email bodies as incomplete: they often contain the message text but not the sender header/address. Do not infer or confidently invent corporate email formats from a name/domain. If the session only proves the person’s identity but not the actual address, say that plainly and recommend replying to the original email thread or checking the original sender field. Public lookup sites can identify the person/role, but masked addresses from sales-prospecting pages are not enough to present a verified email.

### Personal reminders and lightweight todo systems

Use this when Semyon asks to move reminders, create a simple todo list, or have Camille/admin track recurring personal tasks. First list existing cron jobs before changing reminders; move only life-admin/reminder/event jobs into the Camille channel, leaving engineering, system monitoring, cleanup, and watcher jobs in their existing specialist channels unless Semyon explicitly asks for all noise to move. De-duplicate obviously identical one-shot reminders before they fire. For a lightweight todo system, prefer a plain Markdown file with Active / Waiting / Done sections plus a daily cron digest that reads the file, rather than creating many scattered reminder crons with no central list.

When Semyon asks “anything else missed?” do not stop at active cron jobs: search session history for already-fired one-shot reminders, “remind me”, “tomorrow”, “follow up”, “long finger”, “shopping list”, and recent assistant recommendations phrased as next actions. Add genuinely still-relevant items to the central todo file instead of recreating stale one-shot crons. Keep categories clean: Active for immediate/due follow-ups, Waiting / Someday for low-urgency shopping, watchlists, or setup tasks, Done for completed items. Avoid mixing repo-agent/ops noise into Camille life-admin unless Semyon explicitly asks.

## General verification

- Verify outputs in the surface the user will consume: map links, rendered blog page, notebook result, Discord target, or created todo file.
- Keep generated the local supporting file inside this skill’s `scripts/`, `templates/`, or `references/` directories instead of creating one-off sibling skills.
- If the task touches a repo, run the repo’s build/checks before declaring success.
