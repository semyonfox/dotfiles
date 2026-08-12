---
name: local-video-transcription
description: "Use when transcribe YouTube or local video/audio using Semyon's local faster-whisper server pipeline, with yt-dlp acquisition and verified artifacts."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]

metadata:
  harness: [hermes]
---

# Local video transcription

Use this whenever Semyon asks to transcribe a YouTube video, video URL, or local audio/video file. The canonical implementation is the local server pipeline at `~/transcriptions/`; **do not substitute YouTube captions for a local Whisper transcription**.

## Non-negotiable rule

For a request to *transcribe*, the deliverable must be produced by `~/transcriptions/transcribe_video.py` unless Semyon explicitly asks for platform captions. YouTube captions may be used only as an optional comparison/reference artifact and must be labelled as such, never presented as the requested transcription.

## Canonical pipeline

- Project root: `/home/semyon/transcriptions`
- Environment: `/home/semyon/transcriptions/.venv`
- Downloader: `/home/semyon/transcriptions/.venv/bin/yt-dlp`
- Canonical runner: `/home/semyon/transcriptions/run_transcription.sh`
- Transcriber: `/home/semyon/transcriptions/transcribe_video.py`
- Engine/model: `faster-whisper`, default `large-v3`
- Runtime policy is CUDA-only by default: `int8_float16` then `int8`. CPU fallback requires the explicit `--allow-cpu-fallback` flag, preventing an unnoticed slow CPU run.
- The decoder uses `condition_on_previous_text=False` with `hallucination_silence_threshold=2` to prevent repeated-segment loops during long-video outros/silence.
- Always invoke the shell runner, not Python directly: it exports the virtualenv’s bundled NVIDIA `cublas`/`cudnn` paths **before Python starts**, which is required by CTranslate2. Setting `LD_LIBRARY_PATH` inside Python is too late for some loader paths.

The script writes:

- `transcript.in-progress.md` — incremental progress; incomplete until the process exits successfully
- `transcript.md` — final timestamped transcript
- `transcript.plain.txt` — final plain text
- `transcript.raw.json` — final segments plus model/runtime/language metadata
- `transcript.segments.jsonl` — incremental segments

## Workflow

### Follow-up URLs in an active transcription thread

When Semyon posts a bare follow-up such as “on this: <YouTube URL>” immediately after asking for a local transcription, summary, and Obsidian note, treat it as a request to repeat the **same deliverable set** for the new source: locally transcribe the full video, create a grounded summary note, preserve and link the transcript inside the vault, and attach both Markdown files. Do not make him restate the workflow.

- Preserve a timestamp query such as `&t=1366s` in the source link and use it as a priority passage in the note when relevant.
- Transcribe the full source unless he explicitly asks for a clip-only transcript; the timestamp is normally a review anchor, not an instruction to discard the rest of the video.
- If the anchor contains personal allegations, disputes, or other unverified claims, describe the passage cautiously and extract the general lesson. Do not repeat the claim as established fact in the note.

### 1. Discover the local project before doing anything else

```bash
test -x /home/semyon/transcriptions/.venv/bin/yt-dlp
test -x /home/semyon/transcriptions/.venv/bin/python
test -f /home/semyon/transcriptions/transcribe_video.py
```

Inspect `transcribe_video.py` if its interface or defaults are uncertain. Do **not** install a separate temporary `yt-dlp`, scrape captions in a browser, or invent a different pipeline when this project exists.

### 2. Create a stable output directory

Use the source title as a safe directory name beneath `/home/semyon/transcriptions/`. Keep the original audio and `source.info.json` there so the transcript is reproducible.

Example:

```bash
OUT_DIR='/home/semyon/transcriptions/<safe title>'
mkdir -p "$OUT_DIR"
```

Do not overwrite another completed transcript directory without checking it first.

### 3. Download YouTube audio through the project’s yt-dlp

For a YouTube URL:

```bash
/home/semyon/transcriptions/.venv/bin/yt-dlp \
  --no-playlist \
  --extract-audio --audio-format wav --audio-quality 0 \
  --write-info-json \
  --js-runtimes "node:$(command -v node)" \
  -o "$OUT_DIR/source.%(ext)s" \
  '<youtube-url>'

stat --printf='%n %s bytes\n' "$OUT_DIR/source.wav" "$OUT_DIR/source.info.json"
```

If `node` is unavailable, omit `--js-runtimes` and report the actual yt-dlp result. Do not silently switch to caption downloading.

For a local source, pass the existing media file directly to the transcriber and still use a dedicated output directory.

### 4. Run the actual local transcription service

```bash
/home/semyon/transcriptions/run_transcription.sh \
  "$OUT_DIR/source.wav" \
  --out-dir "$OUT_DIR" \
  --model large-v3 \
  --language en
```

Before a long job, run an 8-second smoke transcription through this runner and inspect `transcript.raw.json`; it must report `{"device": "cuda", "compute_type": "int8"}` (or another CUDA type). Do not start the full job if this check fails.

For long videos, run in a tracked background process with completion notification. Do not claim the transcription is complete merely because `transcript.in-progress.md` exists.

While running, progress can be checked read-only:

```bash
stat --printf='%s bytes; modified %y\n' "$OUT_DIR/transcript.in-progress.md"
tail -n 8 "$OUT_DIR/transcript.in-progress.md"
nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv,noheader
```

### 5. Verify final artifacts before delivery

Only after the process has exited with code 0:

```bash
test -s "$OUT_DIR/transcript.md"
test -s "$OUT_DIR/transcript.plain.txt"
test -s "$OUT_DIR/transcript.raw.json"
python3 - <<'PY'
import json
from pathlib import Path
out = Path('<output-dir>')
data = json.loads((out / 'transcript.raw.json').read_text())
assert data['segments'], 'No transcript segments'
assert data['metadata']['model'] == 'large-v3'
print({
    'segments': len(data['segments']),
    'duration_seconds': data['metadata']['duration'],
    'runtime': data['metadata']['runtime'],
    'language': data['metadata']['detected_language'],
})
PY
```

Replace `<output-dir>` literally before executing. Check the beginning and end of `transcript.md` for non-empty, plausible content **and inspect the final 2 minutes for repeating alternating segments or timestamps beyond the source duration**. If a quality problem is found, quarantine that run in a clearly named subdirectory and rerun with the decoder settings above; do not replace the result with YouTube captions without explicit approval.

### 6. Deliver the correct file

Attach `transcript.md` by default. Mention that it was generated locally with `faster-whisper large-v3`, and provide the output directory. Attach `transcript.plain.txt` only if requested or useful.

### 7. When the user asks for a summary or an Obsidian note

Create the derived note **only after** the final transcript passes verification. Ground every claim and timestamp in the local transcript; links should use the source URL with `&t=<seconds>s`.

- Capture the source title, channel, publication date (from `source.info.json`), duration, and local transcription runtime/model.
- Prefer a useful synthesis over a transcript rewrite: the central method, practical takeaways, limitations, and timestamped clip candidates when requested.
- Follow the vault's local `AGENTS.md` and an adjacent note's frontmatter/style before writing.
- If Semyon asks to **save and link the transcript in Obsidian**, copy the verified final `transcript.md` into the note's vault folder under a human-readable title, add an Obsidian wikilink from the derived note, and verify the copy matches the generated transcript with `sha256sum`. Do not merely link to an absolute path outside the vault: it will not be portable or sync with the note.
- If the user also asks to commit and push in a dirty vault, stage **only** the derived note and its copied, vault-local transcript when one was requested; never use `git add .`. Before committing, run `git diff --cached --check`, do a lightweight staged secret scan, and confirm the staged name-status contains only those intended artefacts. Fetch first and inspect `origin/<branch>..HEAD` so pre-existing local commits are not accidentally published. Verify the remote branch SHA after the push.
- **Dirty-vault publishing:** when unrelated edits, deletions or untracked files prevent a safe update of the active checkout, do not stash, reset, rebase or disturb them. Instead, create a temporary clean Git worktree from the fetched remote base, copy only the requested note/transcript into it, stage and validate those exact paths, commit there, then push and verify the remote SHA. This preserves active vault work while delivering the requested artefacts.
- If the vault has unrelated dirty changes or has diverged from `origin/<branch>`, do **not** rebase, pull or stage in the normal checkout. Create a temporary clean worktree from the freshly fetched remote branch; copy only the note and vault-local transcript into it, stage those exact paths, run `git diff --cached --check` plus a lightweight secret scan, commit and push. Verify the remote branch SHA afterwards. This preserves active Obsidian/other-agent work while publishing the requested artifacts.
- When the user asks to be taught the material, lead with the governing mental model, then explain only the key principles with practical examples and trade-offs. Do not merely paraphrase the video chronologically.
- When the user asks for a compact summary or an action summary, put a brief **Things to try / action summary** at the end. Make each item concrete, testable, and relevant to their active projects; avoid generic advice.
- If Semyon asks to **save and link the transcript in Obsidian**, copy the verified final `transcript.md` into the note's vault folder under a human-readable title, add an Obsidian wikilink from the derived note, and verify the copy matches the generated transcript with `sha256sum`. Do not merely link to an absolute path outside the vault: it will not be portable or sync with the note.
- If the user also asks to commit and push in a dirty vault, stage **only** the derived note and its copied, vault-local transcript when one was requested; never use `git add .`. Before committing, run `git diff --cached --check`, do a lightweight staged secret scan, and confirm the staged name-status contains only those intended artefacts. Fetch first and inspect `origin/<branch>..HEAD` so pre-existing local commits are not accidentally published. Verify the remote branch SHA after the push.
- **Dirty-vault publishing:** when unrelated edits, deletions or untracked files prevent a safe update of the active checkout, do not stash, reset, rebase or disturb them. Instead, create a temporary clean Git worktree from the fetched remote base, copy only the requested note/transcript into it, stage and validate those exact paths, commit there, then push and verify the remote SHA. This preserves active vault work while delivering the requested artefacts.
- If Semyon also asks to pull the published transcription note onto his PC, preflight the PC vault over SSH: confirm repository/branch/remote, fetch and record ahead/behind, preserve and report existing dirty state, and refuse only if the exact target paths already exist locally. Use `git pull --ff-only` rather than a merge/rebase that could entangle unrelated local WIP. Verify the PC `HEAD` equals the pushed SHA and both note and transcript exist with non-zero sizes. Mention separately if the pull necessarily includes other already-remote commits.

## Failure handling

- **yt-dlp failure:** report its real error; retry only with a justified yt-dlp option change. Do not fall back to captions.
- **CUDA failure:** the script tries alternate CUDA formats, then fails by default. Use `--allow-cpu-fallback` only when Semyon explicitly accepts a CPU run.
- **Very long transcription:** leave the tracked process running and report it as in progress with the actual output path. Deliver only after final artifact verification.
- **Captions available:** irrelevant unless the user specifically asks for captions rather than a transcription.

## Acceptance checklist

- [ ] Used `~/transcriptions/.venv/bin/yt-dlp` for YouTube acquisition
- [ ] Created/used a dedicated reproducible output directory
- [ ] Ran `transcribe_video.py`, not a caption fetcher
- [ ] Verified final `transcript.md`, `transcript.plain.txt`, and `transcript.raw.json`
- [ ] Reported actual model/runtime and transcript path
- [ ] Never represented YouTube auto-captions as the local transcription
