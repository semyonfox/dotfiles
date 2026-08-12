# Markdown editor PR-lane orchestration

Use when Semyon wants a Markdown/editor modernization done quickly without betting the project on one large package migration or polluting `dev`/`main`.

## Durable approach

1. **Do not start by migrating the main editor package.** For Oghma-style canonical Markdown editors, keep CodeMirror as the production write-surface until a spike proves a hard ceiling. Treat Milkdown as the escape hatch, not the first move.
2. **Split the work into mergeable PR lanes from `origin/dev`:**
   - contract/tests/docs for supported Markdown syntax;
   - shared renderer variants;
   - CodeBlock visual chrome while keeping Highlight.js;
   - writer task checkbox interaction;
   - writer math widgets/decorations;
   - optional Shiki-in-CodeBlock later.
3. **Create one clean worktree and branch per lane.** Do not touch dirty/stale normal checkouts. Each branch should be independently reviewable and one commit ahead when handed off.
4. **Delegate one orchestrator agent per lane** with permission to subdelegate. Give each agent its worktree, branch, scope boundaries, exact non-goals, verification commands, and a no-push/no-PR rule unless explicitly approved.
5. **Make package changes only in the lane that needs them.** Renderer consolidation, codeblock chrome, task widgets, and math widgets should not require an editor-engine migration. Shiki belongs in a later controlled CodeBlock lane; Milkdown belongs in a separate spike only if CodeMirror polish still feels wrong.
6. **Verify child self-reports.** After delegation, inspect each worktree with `git status`, `git diff --stat`, and logs/commands. If acceptable, commit locally with a clear message, but do not push/open PRs without approval.
7. **Report merge order, not just branch list.** Recommended order for Oghma-style work: contract → renderer consolidation → CodeBlock chrome → task widgets → math widgets → optional Shiki.

## Package decision rule

For quick delivery, the end-goal package stack for the next production slice is usually:

- editor: CodeMirror 6;
- canonical storage: Markdown;
- renderer: `react-markdown` + `remark-gfm` + `remark-math` + `rehype-katex` + `rehype-sanitize`;
- code highlighting: Highlight.js short-term, Shiki later inside `CodeBlock` only;
- math: KaTeX.

Avoid migrating the main editor to Milkdown/MDXEditor before the above lanes prove where CodeMirror actually fails. Build package-independent contracts/components/helpers first so a future editor adapter can reuse them.

## Visual-proof pitfall

Do not claim “visible improvement” from functional renderer changes unless screenshots show it. For Markdown renderer work, compare the correct rendered surface (`/syntax-guide`, preview/read surfaces, chat/quiz rendered markdown), not the CodeMirror write surface. Use zoomed crops around code/math/table blocks and explicitly distinguish:

- functionally better;
- architecturally safer;
- visibly cleaner.

If the user says they cannot notice the difference, treat that as signal that the branch is plumbing/architecture, not product polish.