# Two-voice Edge and Seol delivery notes

## Verified voice pair

For Semyon's technical-learning series, the default two-speaker pairing is:

- `en-IE-ConnorNeural` — lead narrator
- `en-IE-EmilyNeural` — sceptical co-host

They are distinct enough to make turn-taking legible while remaining calm and appropriate for technical material. Do not treat these exact voice IDs as a universal availability guarantee; verify the local provider before rendering in a new environment.

## Segment approach

Do not attempt to make one TTS invocation play two speakers. Store ordered segments in JSON, render each segment with its assigned voice, then use FFmpeg's concat demuxer. All Edge-rendered segments in this workflow were compatible as 24 kHz mono MP3 and concatenated without re-encoding.

Example manifest shape:

```json
[
  {"speaker":"Connor", "voice":"en-IE-ConnorNeural", "text":"Opening puzzle."},
  {"speaker":"Emily", "voice":"en-IE-EmilyNeural", "text":"Useful objection."}
]
```

Check the merged output with `ffprobe` for non-zero duration and expected size.

## Seol opaque-origin audio caveat

Seol pages are served within a restrictive opaque-origin sandbox. An MP3 at a normal relative URL can be directly reachable and correctly typed as `audio/mpeg`, yet fail to initialise inside an `<audio>` player on the hosted page.

**Working delivery method:** embed the verified MP3 in the page source as:

```html
<source src="data:audio/mpeg;base64,ENCODED_AUDIO" type="audio/mpeg">
```

Seol's CSP allows `media-src 'self' data: blob:`, and the data source rendered enabled controls in public-browser verification. Keep Seol's upload size limits in mind; this is appropriate for compact narrated chapters, not long/high-bitrate recordings.

After publishing or replacing, verify:

1. The public page title and intended chapter metadata appear.
2. Audio controls are enabled in a real browser snapshot.
3. The page URL remains the expected existing series URL.

When the page is part of an ongoing series, use `seol replace PAGE_ID site` rather than a new publish command to preserve the listener's link.
