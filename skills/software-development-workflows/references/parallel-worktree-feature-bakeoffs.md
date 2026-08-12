# Parallel worktree feature bakeoffs

Use when Semyon asks to compare several implementation directions without polluting `dev`/`main`, especially for frontend/editor/performance work.

## Shape

1. **Start from the remote base, not the dirty checkout.** Fetch the target branch and create one isolated worktree per candidate from `origin/<base>` with agent-owned branches such as `agent/<feature>-<candidate>`. Leave the normal checkout untouched, even if it is dirty or behind.
2. **Delegate one worker per worktree.** Give each worker a narrow candidate brief, exact worktree path, branch name, files/areas allowed, package-manager rule, and a hard reminder not to touch the dirty checkout or other worktrees.
3. **Keep a clean reference worktree.** Include a `base` worktree from the same remote commit for screenshots, production builds, and performance baseline.
4. **Use the same fixture across variants.** Seed deterministic content that stresses the feature under test. For Markdown/editor bakeoffs, include headings, lists, tasks, tables, code fences with language + metadata/title, unknown languages, long lines/wrap, math, links, inline code, and hostile-looking HTML/script inside code fences.
5. **Authenticate deterministically.** For local/mock Oghma-style apps, prefer a disposable seeded user and a short-lived test-only cookie/JWT over UI-login flakiness. Verify the audited page is the authenticated target, not a redirect/login page.
6. **Build and run each variant independently.** Use production builds on separate ports. Do not compare dev servers for performance.
7. **Capture evidence.** For each variant: status/diff summary, build/test commands, authenticated screenshots, browser console/page errors, and Lighthouse/Unlighthouse metrics. Create labelled side-by-side composites, including cropped views around the feature if full-page screenshots are too small.
8. **Compare as product directions, not just code diffs.** Separate safe PR-sized work, structural follow-ups, heavy/experimental implementations, and editor-engine spikes. Recommend a sequence and explicitly say what not to merge yet.

## Verification checklist

- `git worktree list` shows separate candidate worktrees.
- The dirty main checkout is unchanged.
- Every candidate production-builds or has a concrete blocker.
- The same fixture and auth path were used for every variant.
- Screenshots and perf reports are stored outside the repo, e.g. `/tmp/<project>-eval/...`.
- Final answer names the preferred direction, follow-up order, and rejected/held candidates.

## Pitfalls

- Do not apply old local patches onto a stale branch when `origin/<base>` has moved; create fresh worktrees from the remote base and port intent forward.
- Do not let a candidate's self-report stand unverified. Inspect real `git status`, `git diff --stat`, builds, screenshots, and perf outputs yourself.
- Do not treat editor-engine spikes as production PRs. Keep them isolated behind internal/dev-only routes or feature switches until round-trip fidelity, security, bundle cost, and UX pass.
- If Unlighthouse/Lighthouse silently audits a login page, the metrics are junk; always verify route/body/cookies.
