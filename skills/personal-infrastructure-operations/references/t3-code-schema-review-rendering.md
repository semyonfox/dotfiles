# T3 Code SQLite schema review and rendered diagram handoff

Use after T3 state recovery/dedupe when Semyon puts the merge/import on hold and asks to understand the SQLite schemas, compare versions, or receive rendered PDFs/Mermaid diagrams.

## Trigger phrases

- "put the merge on hold"
- "tell me about the schemas"
- "render the PDFs"
- "Mermaid high quality over different versions"
- "send them over"

## Workflow

1. **Freeze posture:** explicitly treat merge/import as on hold. Inspect only; no live DB writes.
2. **Identify DB set:** include live `/home/semyon/.t3/userdata/state.sqlite` plus staged merge DBs under the latest `/home/semyon/t3-data-staging-*/db/*.sqlite`.
3. **Inspect each DB read-only:** collect table list, column list, row counts, `PRAGMA integrity_check`, `PRAGMA foreign_key_check`, schema SQL hash, indexes, and foreign keys. Use SQLite immutable/read-only URI where possible.
4. **Classify schema versions:** compare each staged schema hash to live. Same hash = import candidate for a later dry-run; different hash = preserve/archive unless a deliberate migration is written.
5. **Check meaningful diffs:** same table count can still differ by column shape. Report table-only and column-level differences. In this session the durable pattern was:
   - current live and `merged_schema_2_current` shared the same schema hash;
   - older schema had the same table names but auth tables differed (`role` vs `scopes`/`proof_key_thumbprint`);
   - tiny/odd schema had many workflow/board/ticket tables and an extra `projection_threads.hidden` column.
6. **Generate human and machine artifacts:** write `schema_inspection.json`, a concise Markdown report, and Mermaid `.mmd` files for:
   - version overview / compatibility map;
   - ER diagram per DB;
   - dependency/flow diagram per DB.
7. **Render high-quality outputs:** use `bunx --bun @mermaid-js/mermaid-cli` to render SVG, high-scale PNG (`-s 3` or higher), and PDF. If Chromium sandboxing is a problem, use a Puppeteer config with `--no-sandbox`, `--disable-setuid-sandbox`, and `--disable-dev-shm-usage`. For a report PDF, a local Playwright/Chromium binary can print an HTML report to PDF.
8. **Package and send:** create a `tar.gz` containing `.mmd`, `.svg`, `.png`, `.pdf`, JSON, Markdown, and HTML. Send the pack plus the main report PDF and key diagrams as `MEDIA:` attachments.
9. **Final answer:** lead with the compatibility verdict, not the file list. State clearly that live was not modified.

## Artifact layout

Recommended under staging:

```text
/home/semyon/t3-data-staging-YYYYMMDD-HHMMSS/_schema_report/
├── schema_inspection.json
├── t3-schema-report.md
├── t3-schema-report.html
├── t3-schema-report.pdf
├── schema-versions-overview.mmd/.svg/.png/.pdf
├── live_current-er.mmd/.svg/.png/.pdf
├── live_current-flow.mmd/.svg/.png/.pdf
├── merged_schema_N-*.mmd/.svg/.png/.pdf
└── puppeteer-config.json
```

Package example:

```bash
cd /home/semyon/t3-data-staging-YYYYMMDD-HHMMSS/_schema_report
tar -czf /home/semyon/t3-schema-render-pack-YYYYMMDD-HHMM.tar.gz .
```

## Reporting template

```text
Merge is on hold. I only inspected/rendered.

Schema verdict:
- live_current: canonical, untouched
- merged_schema_2_current: same schema hash as live; only sensible candidate for later projection-only import dry-run
- merged_schema_1_older: older auth column shape; archive/reference
- merged_schema_3_tiny: odd/tiny workflow-heavy schema; preserve, do not direct-import

Artifacts:
MEDIA:/path/to/t3-schema-render-pack-....tar.gz
MEDIA:/path/to/t3-schema-report.pdf
MEDIA:/path/to/schema-versions-overview.pdf
MEDIA:/path/to/merged_schema_2_current-er.pdf
```

## Pitfalls

- Do not confuse “same table names” with “same schema”; column-level auth changes matter.
- Do not directly import old auth/pairing rows merely because schemas match.
- Do not leave only `.mmd`; Semyon asked for rendered, high-quality outputs, so deliver PDF/SVG/PNG too.
- Do not report a missing `zip` command as a durable issue; `tar.gz` is fine for Discord handoff.
- Do not let this step drift back into merge/import work. The requested deliverable is schema understanding and rendered artifacts.
