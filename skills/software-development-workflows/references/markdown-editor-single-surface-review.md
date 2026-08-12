# Markdown editor single-surface review notes

Use this when reviewing or finishing a migration from multiple Markdown modes into one CodeMirror-backed, Notion-ish writing surface.

## Review surface

Trace at least two layers beyond the changed component:

- editor container state (`loaded`, `localContent`, dirty/save/error flags)
- CodeMirror lifecycle and external value sync
- draft cache read/write/cleanup paths
- note fetch/mutate store interactions
- cross-pane or multi-instance sync events
- router/pane keying that causes editor unmount/remount
- preview/syntax-guide surfaces that may still depend on render-only Markdown
- stale source/read mode files or mode stores
- global CSS selectors scoped to CodeMirror/editor classes

## CodeMirror external sync pitfall

When React state pushes a new value into CodeMirror, do not let the normal `updateListener` treat the transaction as a user edit. A full-document dispatch for cache/API/cross-pane updates can otherwise mark a clean note dirty, show bogus `Unsaved`, and write drafts containing already-saved server content.

Pattern:

- Define a CodeMirror `Annotation` for external/programmatic sync.
- Add it to value-sync dispatches.
- In the update listener, detect the annotation and pass a `programmaticUpdate` flag to the parent.
- Parent updates local content but skips dirty/draft writes for programmatic updates.
- Also consider `Transaction.addToHistory.of(false)` so external sync does not pollute undo history.

## Draft debounce cleanup pitfall

If draft writes are debounced, editor cleanup must not merely clear the timer. Switching files/panes often unmounts the editor before the debounce fires. On cleanup/file change, if the editor is dirty, flush the latest content ref to the draft cache before teardown.

## Merge-readiness signals

A PR is much safer to merge when all of these are true:

- visual smoke confirms only the intended single editor surface remains; no stray Source/Read controls
- targeted editor lint/tests pass
- full suite and build pass with project-specific env caveats applied
- `git diff --check` is clean, especially after line-ending edits
- CI PR smoke passes after the final force-push/amend
- stale mode files/stores are either deleted or explicitly identified as harmless cleanup debt
