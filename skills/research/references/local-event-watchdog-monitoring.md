# Local event watchdog monitoring

Use this when turning a user's high-value local venue/community into a low-noise recurring monitor.

## Pattern

- Treat the venue/community itself as the signal, but filter alerts to the user's concrete interests (e.g. tech, startup, career, AI, infrastructure), not every event at the venue.
- Prefer official event pages first, then community organiser pages (Eventbrite/Meetup/ConnectedHubs) as secondary discovery sources.
- Before creating anything new, list/inspect existing event/news radar cron jobs. If the user says “keep a closer eye on X” or “include X too,” patch the existing radar prompt/source list; do not add a parallel watchdog unless cadence, delivery target, or alert semantics are genuinely different.
- If you accidentally create a separate monitor and the user wanted the existing radar edited, remove/disable the stray cron and clean up any stray script/state after integration.
- Use a script-only cron/watchdog only when the output is deterministic: non-empty stdout means "send this alert"; empty stdout means silent success.
- On first run, initialise state and optionally report current useful items. Subsequent runs should only report new/changed useful items.

## Parsing lessons

- WordPress/Elementor event pages may require a browser-like User-Agent for `curl`; APIs may be blocked even when HTML works.
- Parse event cards/loop-items rather than the whole page, otherwise keywords in surrounding page furniture can produce false positives.
- Score the event title (or title + event-specific detail) rather than the entire page. Whole-page scoring makes unrelated events inherit keywords from other cards.
- Use word-boundary matching for short keywords like `AI`; substring matching will hit unrelated words.
- Many venues reuse a single newsletter/signup URL for several events. Do not dedupe by URL alone; use `url|date|time|title` or a similar event identity.

## Alert shape

Keep alerts short:

```text
New/changed <venue>-adjacent tech event(s):
• <Title> — <Date> — <Time>
  <URL>
```

Avoid long explanations in recurring alerts. The point is surfacing opportunities, not writing a newsletter.
