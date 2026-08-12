---
name: chaptered-audio-learning
description: "Use when use for multi-chapter audio learning series."
version: 1.0.0
created_by: agent

metadata:
  harness: [hermes]
---

# Chaptered Audio Learning

Use when a learner wants a background-listenable series rather than a conventional lesson plan: module notes and real projects are transformed into short, intriguing audio chapters, optionally published as a browsable static learning library.

## Teaching contract

1. Start from a concrete mystery in the learner's actual system, codebase, workflow, or observed failure — never from a toy syntax exercise.
2. Delay the explanation long enough for the question to become interesting. Reveal the mechanism after the learner has a reason to care.
3. Translate each chapter in this order:
   - real system and decision;
   - engineering mechanism;
   - academic/module vocabulary;
   - concise exam framing;
   - a compact resolution or retrieval prompt.
4. Treat source notes as alignment/reference material, not a script to recite. Preserve their terminology but explain it through the learner's own work.
5. Keep each chapter self-contained, but end with a specific unresolved next question that naturally leads to the next chapter.

## Two-voice format

When the user requests two speakers, each voice must have a useful job:

- **Lead host:** establishes the mystery, follows the system, and explains the model.
- **Sceptical co-host:** raises the plausible but incomplete objection at the exact moment it matters, asks for definitions, and forces boundary cases.

Do not add filler banter, personality sketches, or repeated recaps. The second voice exists to create productive friction and retrieval opportunities.

## Voice selection and listener approval

See [TTS provider evaluation](references/tts-provider-evaluation.md) for the audition rubric, verified Edge inventory, and safe ElevenLabs migration boundary.

Treat voice selection as part of lesson quality, not a last-mile rendering detail.

1. Before producing more than a pilot chapter, render the same 30–60-second dialogue excerpt with each candidate pair. Compare naturalness, clarity at work-listening speed, turn distinction, and whether the co-host sounds like a person rather than a "radio AI".
2. Ask for listener approval before committing a voice pair to a series. A nominally local accent is not enough: reject an uncanny voice even if it is the only regional stock option.
3. Separate *provider inventory* from *voice quality*. If a provider exposes only two regional voices, do not blindly rotate between them; research another provider with a browsable/auditionable voice library.
4. Use provider documentation and actual voice previews to establish language/accent support. Do not infer that a provider's support for Irish/Gaeilge automatically proves it has an Irish-English narrator suitable for the series.
5. Keep the approved voice IDs, display names, model/version, speed/style settings, and an audition clip manifest beside the episode sources. This makes rerenders reproducible.
6. If a new voice is selected after publication, backfill a complete logical set of existing chapters before publishing. Never publish a page where some episodes use the rejected co-host and others use the replacement.

## Text-first fallback

Audio is an optional delivery layer, not the learning product. If the listener rejects the available voice quality or asks to stop audio, pivot immediately instead of continuing provider research or publishing a mixed-quality backfill.

1. Pause any audio-producing background job before editing the public learning page.
2. Remove every audio player and embedded audio payload from the published artifact; do not leave dead controls, TTS host names, or "transcript" labels behind.
3. Keep the chapter’s hook, vocabulary, resolution, and full readable body. Rename the body **Lesson** rather than transcript when no released audio exists.
4. Retain the single-book-per-module bookshelf structure. Text lessons remain chapters inside the expandable module book; do not turn the page into a separate reading feed.
5. Verify the public result has zero `<audio>` elements and that the chapter header flows straight into the lesson material.
6. Treat future audio work as opt-in. Do not resume an audio cron job or spend time searching providers unless the listener explicitly reopens that decision.

## Production workflow

1. Inventory modules and project anchors before scripting. Map each chapter to exactly one module and topic.
2. Draft a speaker-labelled dialogue first. Self-review it for: a strong hook, no premature answer, correct terminology, meaningful speaker turns, and an exam-ready ending.
3. Render speaker turns separately with distinct configured TTS voices.
4. Concatenate compatible audio segments using FFmpeg, then verify the finished file with `ffprobe` for format, duration, and non-zero size.
5. Retain the dialogue/transcript beside the generated audio. The transcript must match the released narration.
6. Publish only after the user asked to publish. Verify the public page and its audio controls after deployment.

## Learning-library information architecture

When publishing multiple modules, use one clear library page:

- **Module = book** on a bookshelf/library surface.
- **Topic = chapter** inside its module book.
- A module card/book itself expands to reveal chapters. Do not duplicate it as a separate module listing, chronological episode feed, or reading section.
- Each expanded chapter shows: title, audio player, short concept/vocabulary strip, resolution, and the full transcript visibly inline.
- Preserve every earlier chapter within its owning module, and increment that module's chapter count when adding a new one.
- A chronological release order may exist in metadata, but must not become the primary learning navigation.

## Static publishing and embedded audio

For a restricted static-host sandbox, test the audio player on the public page rather than assuming a relative asset URL works. If the host permits `data:` media sources and relative audio fails in the sandbox, embed `data:audio/mpeg;base64,...` in the player source. Verify this does not exceed the host's upload limits and that the page's audio controls initialise publicly.

Use relative files or normal asset hosting where the target host supports them; embedding audio is a compatibility workaround, not a universal default.

If a text-only revision removes players but the workspace still contains historical MP3 assets, publish/replace the standalone `index.html` rather than the whole site directory. This avoids uploading obsolete media and prevents the host's directory-upload size limit from blocking the lightweight revision.

## Quality gates

Before calling a chapter complete, verify all of the following:

- The project claims in the script match inspected source material.
- Both voices are audible and the final audio duration is credible for the script.
- The transcript has every dialogue turn and is readable without another nested disclosure.
- The module/book is the only navigation representation for that content.
- The public URL shows the updated content and playable audio.

## Pitfalls

- Starting with Java/API ceremony instead of a real problem the learner already understands.
- Explaining the answer before the listener has felt the problem.
- Treating a queue, transaction, lock, and database as interchangeable correctness tools.
- Making a co-host a decorative narrator instead of a source of useful objections.
- Creating a second chronological page/list that duplicates the bookshelf modules.
- Hiding transcripts behind a second nested accordion when the learner explicitly needs a readable reference.
- Claiming an audio deployment works without checking the actual public player.
