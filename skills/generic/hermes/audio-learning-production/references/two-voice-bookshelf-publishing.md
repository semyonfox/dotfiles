# Two-voice study chapters on a single static bookshelf

Use for Semyon's background-listenable university learning series.

## Format that works

- Treat each module as **one expandable book** on a bookshelf page; teaching topics are chapters inside that one book.
- Do not also render a separate chronological feed, second module list, or per-episode page.
- When a book opens, show each chapter's player, key vocabulary, short resolution, and the **full transcript inline directly below the player**. Do not hide the transcript behind an additional disclosure.
- Use a two-person script with a real pedagogical division: a lead narrator introduces the puzzle and builds the model; a sceptical co-host asks the useful objection. Do not insert radio-style filler banter.
- Begin from a project-specific failure/decision, reveal the core mechanism gradually, connect to academic vocabulary and an exam framing, then resolve the opening question.

## Rendering and verification

1. Keep an ordered JSON dialogue manifest (`speaker`, `voice`, `text`) as source.
2. Render each turn with the selected TTS voice and concatenate in order with FFmpeg.
3. Verify final audio with `ffprobe` before publication.
4. Generate the visible transcript from the same dialogue manifest so it cannot drift from the audio.

## Seol static-publishing caveat

Seol pages run in an opaque-origin sandbox. In this workflow, a relative MP3 asset could be fetched directly but did not initialise from the embedded audio player. Embedding it as `data:audio/mpeg;base64,...` worked reliably under Seol's allowed `media-src` policy.

- Keep a page-size budget: base64 increases audio payload by roughly one third, and Seol deployments may have upload-size limits.
- Always test the published page's actual audio controls, not only the direct asset URL.
- Keep the original MP3 files and dialogue manifests locally even when embedding audio for publication.
