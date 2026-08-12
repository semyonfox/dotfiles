# Long profile ingestion lesson, 2026-06-05

## Situation

The user supplied a long cleaned personal profile and asked to ingest it into memories. The payload included identity, education, projects, priorities, writing preferences, sensitive adoption/origin-name context, homelab details, career path, and stale facts to discard.

## What worked

- Saved compressed durable facts rather than the full profile verbatim.
- Replaced stale/placeholder user-profile entries with canonical current facts.
- Removed junk promoted memory fragments that were consuming memory budget.
- Added sensitive identity context in concise form to prevent future accidental misuse.
- Saved current priorities and project state as compressed steering context.

## Follow-up correction

The user asked, "so you saved it all?" This revealed an important communication pitfall: after ingesting a large profile, the assistant should not simply say "ingested" without clarifying that Hermes memory is a compressed durable-summary store, not a verbatim archive.

## Better completion phrasing

Use language like:

> I saved the durable high-signal version into memory, not the entire profile verbatim. I saved identity/current-name handling, sensitive origin context, current priorities, main project facts, writing preferences, learning style, and homelab/career context. If you want the full profile preserved as a canonical long-form source, I can save it separately as a local reference file or note.

## Durable rule

For long profile ingestion tasks, separate three outcomes explicitly:

1. **Durable memory:** compact facts that steer future sessions.
2. **Stale cleanup:** contradictions/junk removed or replaced.
3. **Optional archive:** full source text saved to a file/note only if requested or explicitly within scope.
