# Schema validator migration triage

Use this when Semyon asks whether to replace Zod with Valibot, ArkType, TypeBox, or another runtime validation library across existing repos.

## Core judgement

Do not treat validator benchmarks as a mandate for bulk migration. First classify each use site by runtime, ecosystem coupling, and migration surface.

Valibot's durable advantages are:

- small, modular, tree-shakeable bundles
- functional `pipe(...)` composition instead of Zod method chaining
- `parse`, `safeParse`, `is`, and `assert`
- `InferOutput` / `InferInput` type inference
- useful for browser and edge runtimes where every KB and startup cost matters

Zod's durable advantages are:

- broad ecosystem support
- many integrations still document or require Zod schemas
- less migration risk in mature code with Zod-specific helpers, error shapes, or JSON-schema conversion

## Repo triage workflow

1. Find actual use, not just dependencies:
   - Package dependency: scan `package.json` for `zod`.
   - Source imports: scan for `from "zod"`, `from 'zod'`, `require("zod")`, `astro/zod`, `zod-to-json-schema`, and framework helpers.
   - Exclude `node_modules`, `.git`, build output, worktrees, archives, templates, report clones, and reference/vendor folders unless the user explicitly includes them.
2. Categorize each hit:
   - **Stale dep**: package depends on Zod but source never imports it. Prefer removing Zod and running tests.
   - **Framework-owned**: e.g. `astro/zod` content collections. Do not migrate unless the framework supports the alternative.
   - **Ecosystem-coupled**: e.g. MCP SDK versions with Zod peer deps, `zod-to-json-schema`, tRPC, generated OpenAPI. Treat as a larger framework/protocol migration, not a quick swap.
   - **Edge/browser local schema**: good candidate for a small Valibot spike.
   - **Server-only low-traffic validation**: usually not worth churn unless there is a bundle/security/dependency reason.
3. Check current upstream docs for the exact integration. Examples from this session:
   - AI SDK structured outputs support Valibot via `@ai-sdk/valibot` and `valibotSchema`.
   - AI SDK tool docs may still phrase `inputSchema` as Zod or JSON Schema; verify whether Valibot schemas are accepted in the installed version before editing.
   - Older `@modelcontextprotocol/sdk` package docs list Zod as a required peer dependency; newer split MCP packages mention Standard Schema compatibility. That implies a possible SDK migration, not just swapping imports.
4. Recommend one narrow spike, not a cross-repo codemod:
   - Use Valibot's codemod only in dry-run first: `npx @valibot/zod-to-valibot src/**/* --dry`.
   - Manually inspect transforms/coercion, defaults, unknown-key behavior, error formatting, `.describe()`, `.pipe()`, and JSON schema generation.
   - Run project-native typecheck/tests/build and compare bundle output if bundle size is the motivation.

## Migration gotchas

- Zod method chains map to Valibot pipelines: `z.string().email().min(2)` becomes `v.pipe(v.string(), v.email(), v.minLength(2))`.
- `z.infer` becomes `v.InferOutput`.
- `z.enum([...])` often maps to `v.picklist([...])`.
- Zod coercion (`z.coerce.*`) has no direct Valibot single-call equivalent; use explicit input plus `v.transform(...)` and be careful with safety.
- Zod object behavior such as `.strict()`, `.passthrough()`, `.catchall()`, and unknown-key stripping needs explicit Valibot equivalents (`strictObject`, `looseObject`, `objectWithRest`, etc.).
- Zod error shapes and custom messages are not identical. If user-facing validation errors are tested, port those tests first.
- JSON-schema conversion is a common blocker. Do not remove `zod-to-json-schema` until the replacement path is verified.

## Good verdict language

- "Remove stale Zod dependency; no Valibot migration needed."
- "Good Valibot spike: edge/browser code with a small isolated schema surface."
- "Not now: ecosystem-coupled Zod use; migrate the surrounding SDK/integration first if there is a real reason."
- "Leave framework-owned `astro/zod` alone unless Astro supports another schema adapter."
