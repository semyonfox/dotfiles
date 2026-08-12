# TTS provider evaluation for two-voice learning audio

Use this as a compact research checklist, not a substitute for auditioning the exact voices.

## Decision rule

Choose on a common 30–60-second, speaker-labelled test excerpt. Score each pair for:

- naturalness and sentence endings;
- intelligibility while working, at ordinary playback speed;
- clear but non-caricatured contrast between hosts;
- delivery of technical names, code terms, and Irish place/project names;
- whether the listener explicitly approves it.

Do not lock a series to an accent label alone. Native/regional stock voices can still sound synthetic.

## Provider facts checked in August 2026

### Microsoft Edge TTS

- The installed `edge-tts --list-voices` inventory exposed exactly two `en-IE` voices: `en-IE-ConnorNeural` and `en-IE-EmilyNeural`.
- This is not a broad enough catalogue for a quality-driven two-host series if either voice is rejected.
- Edge remains useful for free drafts and fast turnaround, but not a reason to compromise the approved production voice.

### ElevenLabs — strongest candidate to audition

- Its public Voice Library advertises 10,000+ voices and categories including conversational, narrator, educational, and regional/accent collections.
- Its Irish TTS page advertises Irish support and regional accents, plus controls for speed, stability, and style.
- Caveat: a page advertised as “Irish” may refer to Gaeilge/language support. Confirm the precise voice is an Irish-English accent through its preview and licensing metadata before using it.
- Recommended selection route: shortlist 3–4 Irish-English narrator/co-host candidates in the Voice Library, audition the shared test excerpt, record the chosen voice IDs/settings, then use the API for reproducible segment rendering.

## Integration boundary

Hermes supports `tts.provider: elevenlabs` when `ELEVENLABS_API_KEY` is configured. Adding an account/key or changing the shared production provider is an external/account configuration change: get user approval before doing it. Keep keys out of scripts, pages, transcripts, and reports.

## Safe migration sequence

1. Preserve original dialogue manifests and source text.
2. Produce one approved pilot and obtain listener sign-off.
3. Re-render all existing published chapters with the selected pair.
4. Verify every file with `ffprobe` and verify transcript-to-audio alignment.
5. Replace the public bookshelf only when the migration set is coherent; do not mix rejected and replacement voices.
