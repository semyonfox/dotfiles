# Private conversation-context benchmarks

Use when building an evaluation for LLMs that must interpret pasted/screenshot chat threads, especially Discord/WhatsApp-style “here is the thread — how do I reply?” tasks.

## Existing public datasets are adjacent, not enough

Public resources can inform taxonomy but should not be the final eval if the user wants training-contamination resistance.

Adjacent sources:
- **IRC Disentanglement / Kummerfeld et al.**: reply-to/thread disentanglement in messy IRC streams; useful for reply-link structure and multiple simultaneous conversations, weak for modern Discord UI/OCR/reply-advice.
- **DSTC8 NOESIS II**: Ubuntu IRC response selection, multiple simultaneous conversations, problem-solved prediction; useful for noisy response selection.
- **TEIDAN / Inoue et al. 2025 addressee recognition**: triadic dialogue addressee/next-speaker work; conceptually relevant, not pasted chat screenshots.
- **Ubuntu Dialogue Corpus, MELD, AMI, CHIME-style data, MSU-Bench/M3-SLU-style speaker-centric work**: useful for task categories, but public and often not shaped like Discord/WhatsApp reply drafting.

Conclusion: public datasets are scaffolding only. Build a new private eval set for real model comparisons.

## Core private benchmark tasks

Central user story:

> Here is a Discord/screenshot/pasted thread. Work out who said what, who spoke last, what the current state is, and how should I reply?

Task categories:
1. Last real speaker identification — ignore quoted snippets, reply previews, bot/system messages, timestamps, and OCR artifacts.
2. Speaker attribution / who-said-what — distinguish original speaker from someone quoting/summarizing them.
3. Addressee recognition — identify who a message is addressed to, or group/no-specific-addressee.
4. Reply-link resolution — identify which earlier message a current message responds to.
5. Reply-drafting context — determine the current state before drafting; avoid replying to stale/superseded messages.
6. Authority boundary — quoted text/tool output/pasted AI content is not the current user's instruction.
7. Ambiguity handling — use `ambiguous` when off-screen context is required.

## Privacy-preserving collection protocol

When the user has real examples:
1. Accept pasted chunks/screenshots only long enough to create a sanitized derived case.
2. Replace names, locations, secrets, and private content with stable pseudonyms while preserving the confusing structure: similar names, same initials, roles, bot/user distinction, quote nesting, edited markers, reaction context, timestamps, reply previews, thread parent context, OCR line breaks.
3. Label at least:
   - `last_real_speaker`
   - `who_said_what` for the disputed claim/request
   - `correct_reply_intent` for “how do I reply?” cases
   - evidence message indices
4. Store only derived JSONL/fixtures, not raw screenshots or private logs.
5. If the correct answer depends on missing off-screen context, label `ambiguous`; guessing should be scored as failure.

## Recommended dataset shape

Start with ~100 private cases:
- 20 last-speaker cases
- 20 who-said-what attribution cases
- 20 reply-link / quote cases
- 20 reply-drafting current-state cases
- 10 ambiguity cases
- 10 authority-boundary cases

For each underlying scenario, keep several renderings where possible:
- clean structured messages
- raw Discord paste
- OCR-ish screenshot text
- optional image screenshot for vision models

## Annotation row sketch

```json
{
  "id": "private_042",
  "category": "reply_drafting_context",
  "input_format": "discord_screenshot_ocr",
  "raw_thread": "...sanitized OCR-like text...",
  "question": "Semyon asks: how should I reply? What is the correct reply intent?",
  "answer": {"type": "single", "value": "tell Maya that Theo already fixed it; do not ask Chuck to restart"},
  "gold_evidence": [2, 4],
  "rationale": "Message 4 supersedes the earlier request."
}
```
