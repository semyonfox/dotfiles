# TypeScript 7: comparable benchmarks and visual reporting

Use this after a TS 5/6 → TS 7 migration when the user asks for the real performance improvement, not vendor headline numbers.

## Benchmark protocol

1. Benchmark the **same checkout**, same `tsconfig`, and same dependency graph. Do not compare an old historical build log with a newly installed checkout.
2. Compare the compiler path actually used by each migration:
   - dual-version projects: explicit TS 6 compatibility binary versus `node_modules/typescript-7/bin/tsc`;
   - direct migrations: install the precise old compiler version in an isolated temporary prefix and call its `bin/tsc` directly, then call the project-local TS 7 binary directly.
3. Use `tsc --noEmit` (plus `-p tsconfig.json` where required) for comparable compiler/typecheck timing. Label it as **compiler/typecheck time**, not total build time: framework builds also include bundling, asset work, tests, and API-dependent tooling.
4. Verify the old compiler version and TS7 version before timing. Never assume bare `tsc` resolves to the desired package after aliases are introduced.
5. Run at least three sequential warm samples for each compiler. Report the median. The first run may warm caches; do not use a single cold run as the comparison.
6. Report old median, TS7 median, speedup (`old / new`), and reduction percentage (`1 - new / old`). Aggregate only comparable typecheck medians; state how many projects were included.
7. Preserve failures as findings. If project-native lint/format checks fail but the explicit TS7 compiler check passes, say that the migration validates the compiler but does not claim the full check is green.

## Example result shape

| Program | Old → TS7 | Old median | TS7 median | Improvement |
|---|---:|---:|---:|---:|
| Project A | 6.0.3 → 7.0.2 | 3.656s | 0.696s | 5.26× / 81.0% less |

## Visual handoff

For a Discord-ready summary, make a 1600×900 single slide with:

- a top-line aggregate result;
- three small summary cards (old → new total, seconds saved, percentage reduction);
- one compact row per program with old/new bars, TS7 time, and speedup;
- an explicit warm-median/typecheck-only footnote.

Use restrained dark grey panels, subtle borders, and orange only as the TS7/accent colour. Visual QA the final raster image: dense tables can silently clip the final row or rightmost column even if the HTML/SVG source looks correct. Ensure every row, the `IMPROVEMENT` header, and footer are present before delivery.