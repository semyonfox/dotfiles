# Local YouTube transcription pipeline

## When to prefer it

For Semyon’s YouTube transcription requests, first check whether the local transcription project is available. Prefer its downloaded-audio → local ASR path over merely retrieving YouTube captions. Captions are useful only as a fallback or comparison source; they are not the requested transcript when a local service/pipeline exists.

## Current project shape

The local project is under `~/transcriptions/` and contains:

- a Python transcription entry point (`transcribe_video.py`)
- a project virtual environment with `yt-dlp` and `faster-whisper`
- `large-v3` transcription with CUDA-first and CPU fallback
- incremental transcript output, plus final Markdown, plain-text, and raw JSON outputs

## Operational pattern

1. Inspect the project entry point and its existing completed-output folder before invoking anything. Reuse its output naming/layout.
2. Use the project’s own `yt-dlp` executable to download audio and metadata into one dedicated directory named after the video.
3. Run the project’s transcription command against the downloaded audio, selecting the project’s normal production model rather than substituting YouTube captions.
4. For long media, run transcription in a tracked background process and point the user to the incremental output while it runs.
5. Do not claim completion until the final transcript artifact exists. Deliver the project-generated final Markdown/plain-text artifact, and retain raw JSON where the project produces it.

## Example invocation shape

```bash
ROOT="$HOME/transcriptions"
OUT="$ROOT/<video-title>"
mkdir -p "$OUT"
"$ROOT/.venv/bin/yt-dlp" --no-playlist --extract-audio --audio-format wav \
  --write-info-json -o "$OUT/source.%(ext)s" '<youtube-url>'
"$ROOT/.venv/bin/python" "$ROOT/transcribe_video.py" "$OUT/source.wav" \
  --out-dir "$OUT" --model large-v3 --language en
```

Exact flags should remain subordinate to the checked-in script and existing project conventions.

## Verification

- Audio and source metadata exist in the named output directory.
- The incremental transcript advances during a long run.
- Final `transcript.md` exists before saying the job is complete.
- Report the model/runtime recorded by the produced artifact, not an assumption.
