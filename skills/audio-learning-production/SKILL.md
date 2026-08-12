---
name: audio-learning-production
description: "Use when producing engaging, hosted two-voice audio lessons."
version: 1.0.0
author: Hermes Agent
created_by: agent

metadata:
  harness: [hermes]
---

# Audio learning production

Use when Semyon wants a lesson, revision series, or academic explainer he can listen to while doing foreground work. Produce a real, finite chapter—not a lecture transcript read aloud—and publish only when he explicitly requests hosting.

## Outcomes

Each chapter should leave the learner with:

1. a resolved engineering or academic puzzle;
2. the formal vocabulary and an exam-ready framing;
3. one applied consequence connected to a real project;
4. a brief retrieval question or challenge.

For Semyon, ground abstract material in his real projects before introducing toy language examples: OghmaNotes, SWIM, Irish Rail Nabber, portfolio work, and infrastructure where relevant.

## Two-voice format

Use dialogue because it pressure-tests the idea, not because fake banter fills runtime.

- **Lead narrator:** sets the puzzle, supplies context, and resolves the conceptual model.
- **Sceptical co-host:** makes substantive objections at the exact point a learner plausibly would: “Why not use a transaction?”, “Why does a retry duplicate work?”, “Who owns the truth?”
- Every exchange must move the explanation forward. Remove greetings, praise, catchphrases, and artificial agreement.
- The final question should be answerable from the chapter, and the episode must resolve its opening hook before ending.

## Chapter scripting protocol

1. **Choose one narrow puzzle.** Start with a concrete failure mode or surprising decision in a familiar project—not a module heading.
2. **Create bounded intrigue.** Explain enough for the listener to predict an answer, then resolve it in the same episode. Never build cliffhangers merely to prolong attention.
3. **Map progressively:** real event → failure mode → invariant/decision rule → formal vocabulary → concise exam phrasing.
4. **Use one project as the primary case study** and one or two short comparative examples only if they sharpen the distinction.
5. **Script the dialogue before synthesis.** Read it through as speech: remove dense lists, explain jargon at first use, and put pauses around major turns.
6. **Self-review before rendering:** check technical claims against the relevant source material; check that the co-host's questions are genuine; check that the answer is not revealed in the opening.

Aim for 5–10 minutes unless Semyon requests another runtime. Prefer one meaningful topic per chapter.

## Rendering a multi-voice episode

Use a structured manifest with ordered `{speaker, voice, text}` segments. Render each separately, then concatenate into one MP3. Verify the merged artifact rather than assuming playback works.

```bash
edge-tts --voice VOICE --text "segment text" --write-media 01-speaker.mp3
# Render each ordered segment.
printf "file '01-speaker.mp3'\nfile '02-speaker.mp3'\n" > concat.txt
ffmpeg -y -f concat -safe 0 -i concat.txt -c copy episode.mp3
ffprobe -v error -show_entries format=duration,size -of default=noprint_wrappers=1 episode.mp3
```

Use a voice pair that is distinct but does not turn the lesson into character acting. See `references/two-voice-edge-seol.md` for the currently verified Semyon setup and Seol delivery caveat.

## Hosted page design

When hosting is requested:

1. Build a focused static page: chapter title, a native audio player, one-sentence premise, three retained concepts, a short challenge, and optional transcript.
2. Keep it readable and chapter-like—not a dashboard. Use generous type scale, high contrast, and one obvious play action.
3. Verify the player locally and on the final public URL.
4. Do not publish source notes that contain private data, credentials, or internal links.

For temporary Seol handoff pages, publish only after the listener has asked for hosting. Use the existing known page ID with `seol replace` when maintaining a series; do not create a surprise new URL.

## Verification checklist

- [ ] Script has one clear puzzle and resolves it.
- [ ] Co-host contributions create useful friction rather than filler.
- [ ] Formal terminology appears after the underlying model.
- [ ] Claims are grounded in source notes/project architecture.
- [ ] Both speakers render in the intended segment order.
- [ ] Final MP3 has a non-zero verified duration.
- [ ] Page shows enabled audio controls at the public URL.
- [ ] Existing public series URL is replaced rather than accidentally forked.
