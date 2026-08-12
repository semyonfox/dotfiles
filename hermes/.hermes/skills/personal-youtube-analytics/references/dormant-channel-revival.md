# Dormant gaming-channel revival assessment

Use this when assessing whether an inactive channel should return and how to turn an existing recording archive into a sustainable publishing workflow.

## Evidence to collect

1. Current channel totals: subscribers, lifetime views, video count, latest upload date.
2. Aggregate analytics for 28, 90, and 365 days: views, watch time, average view duration, subscribers gained/lost, likes, comments, shares.
3. Video-level analytics for 90 and 365 days, joined to titles and publication dates.
4. Recent-upload list to establish the actual dormant period.
5. Read-only footage inventory: roots, file counts, total bytes, game/category distribution, newest files, and likely duplicate/remux pairs.

The useful distinction is:

- **Functioning channel:** active publishing and measurable audience growth.
- **Viable archive:** old searchable/recommended videos still receive views, but the active audience and engagement have decayed.
- **Dead archive:** negligible discovery and no clear historically successful subject or format.

Do not recommend a broad comeback merely because lifetime totals look respectable. Base the initial experiment on the subjects and formats still attracting views during inactivity.

## Low-edit revival strategy

When the creator still records but games and edits less:

- Treat raw-footage abundance and publishing throughput as separate problems.
- Start with one evidence-backed niche rather than mixing every game immediately.
- Run a bounded experiment, usually 6 Shorts over 3 weeks or 8 Shorts over a month.
- Extract one moment, add minimal context and readable captions, and omit intros/logo animation.
- Cap editing time per Short, normally 15–25 minutes. If the format repeatedly exceeds the cap, simplify it.
- Use a reusable 1080x1920 project with fixed caption, facecam, audio, and export presets.
- Prefer two sustainable posts per week over ambitious long-form promises.
- Evaluate after 8–12 uploads: distribution thresholds, repeatable topic/format, returning viewers, and whether the creator can sustain the process.

A useful archive workflow is:

```text
FoxScope/
├── 00-inbox/       # replay-buffer clips or candidate moments
├── 10-selected/    # chosen for editing
├── 20-projects/    # editor projects and assets
├── 30-exports/     # finished, not yet published
└── 40-published/   # uploaded archive
```

For future recording, use an OBS replay buffer or other short-save hotkey so interesting moments enter the inbox directly. A spoken marker such as “clip that” can also create a visible waveform landmark in full-session footage.

## Storage caution

Matching `.mkv` and `.mp4` names may be OBS originals plus remuxes, but names alone are not enough to delete either copy. Before cleanup, compare duration, streams/codecs, dimensions, timestamps, and hashes where applicable. Quarantine with a manifest before deletion.

## Reporting style

Lead with the blunt classification and recommended format. Then provide:

1. evidence from current analytics;
2. the first bounded publishing experiment;
3. a low-friction editing/recording workflow;
4. success and stop/change criteria;
5. storage risks or cleanup opportunities.

Avoid generic creator advice, heroic upload schedules, or treating a large archive as proof that the channel has enough ready-to-publish material.