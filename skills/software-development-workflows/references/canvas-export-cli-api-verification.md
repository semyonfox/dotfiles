# Canvas export CLI and API verification notes

Use when building or reviewing a standalone Canvas LMS archive/export CLI seeded from an app integration or MCP server.

## Canvas API docs facts to verify against

Authoritative docs live under `https://developerdocs.instructure.com/services/canvas/`. Markdown variants are available by appending `.md` to many pages.

Key pages:

- Pagination: `/services/canvas/basics/file.pagination.md`
- Courses: `/services/canvas/resources/courses.md`
- Files: `/services/canvas/resources/files.md`
- Modules: `/services/canvas/resources/modules.md`
- Pages: `/services/canvas/resources/pages.md`
- Assignments/Submissions/Quizzes/Discussions/Conversations as needed under `/services/canvas/resources/`

Important behaviours:

- API access should use HTTPS and `Authorization: Bearer <token>`.
- Canvas IDs are 64-bit; for JS/TS clients, prefer `Accept: application/json+canvas-string-ids` to avoid unsafe integer handling.
- List endpoints are paginated, default to small pages, and must follow the opaque `Link` header `rel="next"`; do not synthesize page URLs beyond adding initial `per_page`.
- File objects include `url` for downloading. Exporters should collect file metadata first, then download from that URL with the same bearer token where required.
- `/api/v1/courses` lists current user's courses and supports `state[]` plus `include[]=term`; for broad user-visible exports, include both `state[]=available` and `state[]=completed`, not only active enrollments.
- Canvas visibility/permission rules are authoritative: hidden, deleted, admin-only, locked, or external LTI content may be inaccessible. Record those in the archive summary rather than failing the whole export.

## CLI implementation pattern

For a fast standalone TypeScript path:

1. Lift working traversal/export behaviour from the app integration, but remove app auth/session/DB/storage/embeddings concerns.
2. Use the MCP server/tool manifest as endpoint inventory, not as runtime dependency.
3. Keep v1 conservative and sequential for Canvas rate-limit friendliness.
4. Add smoke-test limiters (`--max-courses`, `--max-downloads`, `--metadata-only`, skip flags) before running against real credentials.
5. Write both machine-readable manifest and human summary into the zip.
6. Verify with unit tests, typecheck/build, `--help`, and a tiny real Canvas smoke export if a token is already available without printing it.

## Bun single-binary release pattern

Bun can cross-compile TypeScript CLIs into standalone binaries with the runtime bundled:

```bash
bun build ./src/index.ts --compile --target=bun-linux-x64-baseline --outfile ./dist/release/<name>-linux-x64
bun build ./src/index.ts --compile --target=bun-linux-arm64 --outfile ./dist/release/<name>-linux-arm64
bun build ./src/index.ts --compile --target=bun-windows-x64-baseline --outfile ./dist/release/<name>-windows-x64.exe
bun build ./src/index.ts --compile --target=bun-darwin-x64 --outfile ./dist/release/<name>-macos-x64
bun build ./src/index.ts --compile --target=bun-darwin-arm64 --outfile ./dist/release/<name>-macos-arm64
sha256sum ./dist/release/* > ./dist/release/SHA256SUMS.txt
```

Runtime verification is only real on the host architecture you can execute. For the others, verify checksums, public download integrity, and file formats (`ELF`, `Mach-O`, `PE32+`) unless you actually test on those OSes.
