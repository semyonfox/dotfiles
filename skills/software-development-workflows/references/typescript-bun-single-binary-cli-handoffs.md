# TypeScript/Bun single-binary CLI handoffs

Use when Semyon wants a small standalone CLI seeded from an existing TypeScript/JavaScript implementation and wants something easy to send as a single executable.

## When Bun compile is the right first move

Prefer Bun `--compile` over a rewrite when:

- the working implementation already exists in TS/JS;
- the CLI is mostly API traversal, JSON shaping, file/zip output, and progress logging;
- speed of implementation matters more than tiny binary size;
- the user wants a sendable executable without requiring Node/npm on the target machine.

Go is still the boring long-term choice for smaller cross-compiled binaries, but Bun compile is often faster when the source behavior is already JS and the user explicitly chooses TS.

## Workflow

1. Create a standalone repo/package rather than contaminating the source app unless the user asks for an in-repo tool.
2. Copy/adapt the proven source implementation as behavior reference, not blindly as app-coupled code.
3. Strip app dependencies: auth sessions, database, object storage, queues, UI routes, app aliases, and unrelated env requirements.
4. Add explicit CLI flags for bounded smoke tests before any full-account/full-dataset run:
   - `--max-courses` / equivalent scope limiter
   - `--max-downloads` / equivalent binary limiter
   - `--metadata-only` if useful
   - skip flags for slow optional surfaces such as messages/groups
   - per-request timeout flag
5. Keep secrets out of argv where possible by supporting `--token-file` and env fallback. Never print the token; if you must verify loading, print only safe metadata such as domain and token length.
6. Build with:

```bash
bun build ./src/index.ts --compile --outfile ./dist/<tool-name>
```

7. Verify in layers:
   - unit test ZIP/output helpers with mocked downloads;
   - typecheck;
   - compile;
   - `./dist/<tool-name> --help`;
   - tiny real smoke test with hard caps and a shell `timeout` wrapper.
8. Inspect the produced artifact with native tooling, e.g. Python `zipfile`, to confirm manifest/summary/sample entries exist.
9. Commit the standalone repo once it passes.

## Canvas-export-specific notes

For Canvas archive exporters:

- Treat Canvas API access as “everything the token can see”, not hidden/deleted/admin-only/LTI-external content.
- Preserve best-effort behavior: restricted/unavailable endpoints go to a summary file instead of failing the whole export.
- Sequential traversal is a good first version because Canvas rate limiting and permissions are messy; add bounded concurrency only after archive correctness is verified.
- Use the Canvas MCP server/tool manifest as endpoint inventory, and the app exporter as behavior reference.
- Real smoke test shape:

```bash
timeout 75s ./dist/canvas-export \
  --domain universityofgalway.instructure.com \
  --token-file /tmp/canvas-token \
  --out /tmp/canvas-export-smoke.zip \
  --max-courses 1 \
  --max-downloads 1 \
  --skip-conversations \
  --skip-groups \
  --timeout-ms 10000 \
  --progress
```

Then confirm ZIP validity and required entries:

```bash
python3 - <<'PY'
import zipfile, os
p='/tmp/canvas-export-smoke.zip'
print('zip_exists', os.path.exists(p), 'bytes', os.path.getsize(p) if os.path.exists(p) else 0)
with zipfile.ZipFile(p) as z:
    names=z.namelist()
    print('entry_count', len(names))
    print('has_manifest', '_canvas-export-manifest.json' in names)
    print('has_summary', '_canvas-export-summary.txt' in names)
    print('sample_entries', names[:10])
PY
```

## Pitfalls

- TypeScript imports ending in `.ts` need `allowImportingTsExtensions` when using `tsc --noEmit` with Bun-style imports.
- If you add smoke-test skip options to copied JS, make sure nested functions read them from a shared state/options object; copied functions outside the top-level option scope will otherwise throw `options is not defined`.
- Do not run full account exports casually. Canvas traversal can hit thousands of API requests and take a long time.
