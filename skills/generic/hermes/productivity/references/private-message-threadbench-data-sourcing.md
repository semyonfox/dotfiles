# Private message-thread benchmark data sourcing

Use when Semyon wants to build a private benchmark for AI failures on pasted/screenshot chat or email threads: who said what, who spoke last, what is current state, and how should he reply.

## Key principle

Do not rely on public Discord/IRC/email datasets for final scores if the goal is contamination-resistant model evaluation. Public datasets are useful for taxonomy only; final cases should be newly derived from Semyon's private examples or hand-authored from observed failure patterns.

## Source options

- WhatsApp exports
- Discord copied thread chunks or screenshots
- Email threads / Gmail mbox / Takeout
- SMS/iMessage-style exports if available

Prefer export-first over live inbox integration until the benchmark schema is stable.

## Privacy-safe workflow

1. Keep raw exports/screenshots in a private ignored folder such as:

```text
threadbench/raw_private/{whatsapp,discord,email}/
```

2. Immediately create sanitized derived cases. Replace names, phone numbers, emails, addresses, links, exact dates, workplaces/schools, and unusual identifying details.
3. Preserve the structure that creates model errors:
   - reply previews
   - quoted/forwarded text
   - timestamps
   - edited markers
   - reactions if relevant
   - bot/system messages
   - screenshot/OCR line breaks
   - similar names or avatars
   - thread parent/channel context
4. Use stable pseudonyms inside each case, but not necessarily across the whole benchmark. Keep useful roles if they affect interpretation: `User`, `Coach`, `Lecturer`, `Admin`, `SystemBot`.
5. Never commit raw private logs. Store only derived JSONL cases.

## Segmenting conversations

Automated splits are only a first pass. Start a new segment when:

- time gap is roughly 30–120 minutes
- topic changes
- participant set changes
- email subject/thread changes
- Discord thread/channel changes
- a new external event/link/file becomes the topic

For each segment choose a cut point: visible context before the hypothetical reply. Create short, medium, and distractor windows where useful.

## Gold labels

Do not score only free-form reply quality. Add objective labels first:

```json
{
  "last_real_speaker": "Alice",
  "user_identity": "User",
  "current_addressee": "User",
  "who_said_key_claim": "Bob",
  "current_state": "Alice found the notes; no need to resend.",
  "reply_intent": "Acknowledge or say nothing; do not resend notes.",
  "bad_reply_trap": "Replying as if Alice still needs the notes."
}
```

Then ask multiple task questions against the same context:

- Who was the last human speaker?
- Who said the key claim/request?
- Which prior message is the latest reply responding to?
- Is the user expected to reply?
- What is the safest reply intent?
- Draft one short reply.

## High-value failure patterns

Collect or synthesize cases where AI:

- replies to the wrong person
- treats quoted text as the current/latest speaker
- answers a stale request after a later correction/resolution
- misses that Semyon already replied in the pasted context
- confuses similar names/usernames
- treats bot/system output as human conversation
- replies to quoted email history instead of the latest email
- guesses when off-screen context is required; gold should be `ambiguous`

## Recommended initial size

Start small and high-quality: roughly 30 WhatsApp, 20 Discord, and 20 email cases. Expand after inspecting model failures. Huge random exports without gold labels are noise, not a benchmark.