---
name: github
description: "Use when managing GitHub authentication, repositories, branches, issues, pull requests, reviews, releases, or CI via gh or REST."
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]

metadata:
  harness: [hermes]
---

# GitHub Workflow

## Overview

Use this skill for the full GitHub lifecycle: authenticate, clone or create repos, branch and push changes, open pull requests, review diffs, triage issues, and manage CI or releases. Prefer `gh` when it is available and authenticated; fall back to `git` plus `curl` when it is not.

This skill replaces narrow GitHub subskills with one class-level workflow. The detailed recipes are organized by task so you can navigate quickly from auth to repo management to PR review without hunting through separate skills.

## When to Use

- The user asks you to work with a GitHub repo, PR, issue, or release
- You need to decide whether to use `gh` or `git` + `curl`
- You are reviewing local changes before pushing or reviewing a remote PR
- You need to create, label, assign, or close issues
- You need to create a repo, fork one, or manage remotes/releases

## 1) Authentication First

Always determine the auth path before any GitHub API work:

1. Check whether `gh` exists.
2. Check `gh auth status`.
3. If `gh` is unavailable, fall back to `git` + `curl` and locate a token from `GITHUB_TOKEN`, `~/.hermes/.env`, or `~/.git-credentials`.

If auth is unclear, stop and fix auth first. Most GitHub failures are auth failures in disguise.

## 2) Repository Operations

Use this section for clone/create/fork/release/settings tasks.

Common flow:

```bash
gh repo clone owner/repo
# or
git clone https://github.com/owner/repo.git
```

For creation and configuration, prefer `gh repo create`, `gh repo edit`, and `gh release create` when available. Use REST only when you need a specific API field or a noninteractive fallback.

### Recruiter-facing profile and README refresh

When Semyon asks to make GitHub support a placement/internship search, treat the profile and its **actual current pinned repositories** as one public evidence surface. Inspect source, docs, CI and runtime claims before rewriting; keep provenance and security boundaries honest; use clean temporary clones/worktrees when local checkouts are dirty; and stage/push each README independently after default-branch, secret-scan and remote-SHA verification. Do not overwrite private role-specific CV drafts merely because the public profile changes. Full workflow: `references/github-profile-recruiter-readme-refresh.md`.

## 2b) Packaging Repo Content for Delivery

When the user wants a repository-derived bundle sent to them, treat packaging as part of the GitHub workflow, not an afterthought.

1. Resolve the exact source repo and clone or fetch it locally.
2. Identify the precise content scope before archiving. If the user asks for notes plus transcripts/videos/media, verify those assets exist separately; do not assume a markdown vault contains them.
3. Prefer ZIP for non-tarball recipients.
4. If a native `zip` utility is unavailable, use a portable ZIP fallback (for example Python's `zipfile` module) rather than changing the deliverable format.
5. Verify the archive contents by listing the top-level paths and confirming the requested files/folders are present before telling the user it is complete.
6. Be explicit if only part of the requested material was found, and say what is missing instead of implying the bundle is exhaustive.

## 3) Pull Request Workflow

Use this for branch → commit → push → PR → CI → merge.

Core loop:

1. Create a topic branch.
2. Make the change and commit it.
3. Push the branch.
4. Open a PR.
5. Watch CI.
6. Merge or iterate.

Prefer `gh pr create`, `gh pr checks`, `gh pr review`, and `gh pr merge` for the common path. Use `git` + REST only when `gh` is missing.

### User-approved “easy merge” pass

When Semyon explicitly asks to merge the easy/safe PRs from an agent sweep:

1. Re-check each candidate with `gh pr view ... --json state,isDraft,mergeStateStatus,reviewDecision,headRefName,url` and `gh pr checks ... --json name,state,bucket,link --watch=false`.
2. Treat `CLEAN` plus passing real checks as eligible. Skip PRs with failing real app/test checks or ambiguous unstable status unless the user named them directly. Bot-only advisory/status noise can be noted but should not block a clean merge.
3. For bot-only or body-claim-only checks, distinguish trivial inspectable deltas from runtime/CI behavior changes. Use a temporary PR worktree and run the project-native checks before merging production-code or CI-gate changes.
4. If the user says to check with Claude/Fable, use `claude -p --model fable` as a read-only second-opinion reviewer, but do not treat the model verdict as verification. Verification is still CI, local checks, or direct diff inspection. Check Claude auth/readiness first. If the requested reviewer is blocked by quota or provider limits, report that exact blocker and do not substitute another model or merge unless the user explicitly authorizes the alternative.
5. If the PR is draft and eligible, mark it ready first with `gh pr ready`, then verify `isDraft=false`. If its title still contains stale `draft:` wording, edit the title so the public queue is not misleading. When editing titles from scripts, shell-quote the literal title (for example with `shell_quote`/`shlex.quote`) rather than JSON-encoding it; `gh pr edit --title` expects a shell argument, and JSON escaping can leave ugly literal sequences such as `\\u2014` in public PR titles. Re-read the title after editing and repair it before merge/reporting.
6. Do not promote conflicted/`DIRTY` drafts just because the user asked for bulk readiness; report them as blocked until rebased/resolved.
7. Merge with the intended strategy, normally `gh pr merge <n> --squash --delete-branch` for small agent PRs. When working from a temporary worktree and the PR base branch is already checked out by another worktree, `gh pr merge` may fail while trying to run local git operations; retry from a neutral directory with an explicit repo, e.g. `gh pr merge <n> --repo owner/repo --squash --delete-branch`. When multiple PRs target the same integration branch, re-check the next PR's `mergeStateStatus` after each merge; GitHub may briefly show `UNKNOWN` while recomputing, so wait/retry before treating it as blocked.
8. Verify the final state with `gh pr view ... --json state,mergedAt,mergeCommit,url,baseRefName,title` before reporting success, especially after automated ready/title/merge steps.
9. Treat `--delete-branch` as unsafe on long-lived integration/release source branches such as `dev`, `develop`, `staging`, or `release/*`. A `dev -> main` release PR may be merged successfully but `gh pr merge --delete-branch` can delete the remote `dev` branch. Omit that flag for enduring branches. If it was deleted accidentally, restore it deliberately at the post-merge release commit (`git push origin origin/main:refs/heads/dev` after verifying the intended SHA), then fetch and confirm `origin/main` and `origin/dev` match.
10. When a `dev -> main` PR is `DIRTY`, do not squash a `main -> dev` synchronization PR: a squash loses the ancestry relationship and the release PR can remain conflicted. Create the sync branch from `origin/dev`, merge `origin/main` into it, resolve dependency/lockfile conflicts, open its PR to `dev`, and merge that sync PR with `gh pr merge --merge` so the merge commit is retained. Recheck release mergeability and real CI afterwards.
11. If the same user instruction also removes a repo from the recurring allowlist, do not merge that repo’s PR merely because it was previously considered easy; handle the removal separately and leave the PR open unless explicitly told otherwise.

For full repo-agent draft PR queue sweeps, including dirty/local-only blocker salvage and safe temp-worktree cleanup, see `references/repo-agent-draft-pr-unblock-sweep.md`.

## 4) Review Workflow

Use local git diffs for pre-push review and GitHub PR APIs for remote review.

- For a user asking for a quick repo/recent-work summary, do not answer from memory. Resolve the active checkout and remote first, fetch/prune the integration branches, then report: current branch and dirty state, local ahead/behind, recent remote commits, `origin/main..origin/dev` or equivalent release-delta summary, aggregate touched areas, and open PR/check state. If the checkout is dirty, explicitly separate local WIP from remote work and warn before pull/rebase. Session history can supplement context, but live git/GitHub state is the source of truth.
- Local review: `git diff main...HEAD --stat`, then inspect file-by-file.
- For PR/diff review, go one or two dependency layers deeper before posting findings: identify changed public functions/components, trace direct callers/importers, inspect nearby tests, check config/schema/API boundaries, and consider data-flow or migration effects. Post only concrete correctness, test-gap, security, performance, or maintainability findings; avoid vague architecture/style comments.
- For dirty working trees, first separate “local changes not on GitHub” into tracked modifications, untracked files, local commits ahead of remote, generated/cache noise, and local data files. `HEAD` may already match `origin/main`; the missing work may be uncommitted. For jj-colocated repos, prefer `jj status`/`jj diff` for the real working-copy contents; plain `git status` can show Git LFS pointer/smudge/stat noise for images even when `git diff --quiet -- <path>` is clean. Treat test screenshots/dashboard render artifacts as discard candidates unless the user explicitly says to publish them.
- When dirty local work blocks recurring agents, preserve real source/test/doc changes on a WIP branch or isolated worktree before cleanup. Do not blindly commit local databases, cache artifacts, IDE metadata, or large imported binaries; classify them for human approval first. For mixed state, split into: real dev work to preserve, generated noise to restore/ignore, data/content imports needing explicit decision, and personal experiments to delete/exclude.
- For Semyon’s recurring repo-agent specifically, a dirty normal checkout is **not** a default blocker. If the user says to “go from last commit”, “make new worktrees even if dirty”, or “resume all tasks”, update the repo-agent job/prompt so workers fetch origin, choose the preferred base branch, create clean isolated `agent/*` worktrees from `origin/<base>`, and avoid touching uncommitted normal-checkout files. Only block dirty repos when the selected work depends on those uncommitted files, repo metadata/remotes are unusable, or safety policy forbids the action. After changing the cron job, trigger/list it to verify it is scheduled rather than merely describing the desired behavior.
- For dirty repos containing SQLite/DB files, CSVs, PDFs, audio, or `.env` files, verify data safety before proposing a PR: list tracked/untracked data files, inspect SQLite headers for plaintext `SQLite format 3\0`, check reachable git history for prior plaintext DB blobs, and run project encryption verifiers without printing rows/PII. Use `git diff --ignore-space-at-eol --stat` to distinguish real changes from line-ending churn. Detailed checklist: `references/dirty-repo-data-classification.md`.
- For generated-artifact hygiene in a dirty checkout, create a clean worktree from `origin/<base>` and make a tiny isolated PR: add the precise ignore rules, use `git rm --cached <artifact>` to stop tracking generated files while retaining them locally, then prove the rules with `git check-ignore -v --no-index`. Do not edit a dirty `.gitignore` in the primary checkout or delete runtime reports/cache files there. Verify the PR's changed-file list contains only ignores and intended tracked-artifact removals, and re-check the primary checkout’s status before reporting it untouched.
- For repos colocated with jj, use `jj status`/`jj diff` as the source of truth before relying on `git status`: jj may surface working-copy/binary/image changes that a quick Git-only scan can miss or misclassify. Fetch first, compare local bookmarks to `*@origin`, and explicitly report whether the working copy is on an undescribed `@`, whether the integration bookmark is ahead/behind/diverged, and which ignored/generated files are safely local-only. When preparing a PR, rebase the current change onto the lowest intended integration bookmark (`dev` if present, otherwise `main`), `jj describe`, set an `agent/*` bookmark, push with `jj git push --bookmark ... --remote origin`, then open a normal non-draft PR. If local `dev`/integration has already advanced beyond `dev@origin`, push that bookmark first or the PR will appear to include the entire local integration stack; verify with `gh api repos/<owner>/<repo>/compare/dev...<branch>` that the PR is only the intended commit(s). After creating the PR, run `jj new <base>` so the main worktree is clean while the PR change remains on its bookmark. See `references/jj-dirty-worktree-to-pr.md`.
- **JJ + nested-worktree triage:** A nested Git worktree inside a jj-colocated checkout can make `jj status` resolve to the parent working copy. For the candidate worktree itself, use `git -C <worktree> status --short`, `git -C <worktree> diff --name-status`, and direct `HEAD:<path>` blob comparisons. If tracked PNGs/media appear modified under an LFS filter, compare raw working-tree bytes to `git show HEAD:<path>` (or hashes) before reviewing/replacing assets: an LFS clean/smudge mismatch can create phantom image diffs even when every byte is identical. Keep active committed assets; classify only the apparent change as noise. Generated `.husky/_/` Git-LFS hook shims and tool-state directories such as `.agent/` are normally local-only candidates, not source changes.
- **Rebasing docs WIP in jj:** Rebase only after the user has approved publishing their working copy. If a rebase creates conflicts, do not push a conflicted bookmark. Resolve each conflict deliberately with the newer base’s policy/security facts retained, then re-run `git diff --check`, changed-Markdown internal-link validation, and syntax checks for any changed script before pushing/opening the PR. Treat `dev` as the integration target when documented; do not push a docs-cleanup WIP directly to `main` merely to make the normal checkout clean.
- Respect private-fork boundaries and personal artifact hygiene. If Semyon says a fork is for his workflow only, preserve it on his branch/fork and do not upstream PR it. Specific job applications/CVs belong private; public portfolio assets should be generic. For a public portfolio CV, publish the generic PDF/TeX assets from the private CV source repo, verify hashes against the source files, and leave company-specific application variants private. For DB/PII files, verify encryption before committing. See `references/private-forks-and-career-artifacts.md`.
- If the user asks to “push to dev” but the repo only has `main`, treat `dev` as a remote review/integration branch unless they say otherwise: push the current HEAD with `git push origin HEAD:refs/heads/dev`, verify `git ls-remote --heads origin dev`, then open a PR `dev -> main` if they ask to merge it. Do not delete the `dev` branch unless explicitly requested.
- If the user approves an existing PR but says “merge to dev”, do not blindly merge the PR’s current base. Re-check `baseRefName`; if it is not `dev`, edit the PR base to `dev` with `gh pr edit <n> --base dev`, wait for `mergeStateStatus`, and handle `DIRTY` by rebasing only the PR delta onto `origin/dev` (`git rebase --onto origin/dev origin/<old-base> <head-branch>` or equivalent). Force-push the rebased PR branch with lease, re-check checks/mergeability, mark ready if draft, then merge. Verify `gh pr view --json state,mergedAt,mergeCommit,baseRefName` and `git ls-remote --heads origin dev` after merge.
- For dirty repos colocated with a normal checkout already on the target branch, prefer a clean temporary worktree from `origin/<base>` for PR prep. If the first patch application fails because files moved or the base branch advanced, inspect the current base and port the intent manually rather than committing stale paths.
- **Cross-repo stale-branch integration:** a just-pushed topic branch can still be unsafe to merge if it was created from an old `dev`, `main`, or feature branch; its PR may carry unrelated history. For each repository, fetch the intended remote integration base, create a disposable worktree from `origin/<base>`, cherry-pick only the owned commit, run `git diff --check` plus the relevant image/build verification, and push that clean commit on a separate merge branch. Open the PR from this clean branch to the intended base (`dev` where policy says so; otherwise the default branch). For jj-colocated repos, it is fine to cherry-pick the jj-created Git commit inside the disposable regular-Git worktree rather than moving a conflicted long-lived `dev` bookmark. After merge, remove the disposable worktrees; inspect any untracked files first, and force-remove only known generated hook/tool shims such as `.husky/_/`.
- Stage exact files, not `git add .`, when a repo contains env files, backups, generated data, or unrelated dirty work.
- Run a lightweight secret scan over staged files before committing. Exclude lockfiles if the pattern is too noisy, but do not ignore source/config files.
- Verify with the project’s real checks/builds before pushing. If a local tool is missing but the project builds in Docker/CI, use the project Docker build as the verifier rather than treating the missing local binary as the result.
- After push, verify the remote branch advanced and, when the push triggers Jenkins/CI/deploy, wait for that job and inspect the deployed result before saying it is done.
- When updating an existing PR, treat its earlier green checks as stale: re-read the PR head SHA, query the workflow run(s) for that SHA, then re-run `gh pr checks --watch=false` after completion. A successful status from the previous commit does not verify the new delta. For copy-only/public-fallback changes, also inspect the final PR diff to confirm the wording remains generic and does not expose implementation, availability, or defensive-control details.
- When a repo's real deployment path is Jenkins-on-push, do not preserve or trust a stale manual SSH deploy script that points at an old server checkout. Fix the repo-local script to verify locally and make Jenkins ownership explicit, then verify Jenkins build success plus live endpoints. For the portfolio pattern, see `references/portfolio-jenkins-deploy.md`.
- Remote review: fetch the PR branch, inspect the diff, and leave comments only after you understand the full scope.
- Inline comments should be specific, line-accurate, and tied to actual behavior or test gaps.
- For security-sensitive PRs touching auth, rate limiting, abuse controls, secrets, logging, or externally visible errors, explicitly review **public response vs internal observability**. Public messages should be generic and should not reveal that Redis/rate-limiting/token stores or other defensive controls are unavailable; internal logs/metrics should keep the actionable detail. Tests should assert both sides. See `references/security-sensitive-pr-review.md`.
- When asked whether a hardcoded/private-repo API key is valid, validate without printing secrets and separate `auth-valid` from `usable for the intended operation` and from `locally configured`. For OpenAI, a `/v1/models` 200 means the key authenticates, while a tiny Responses call returning `insufficient_quota` means quota/billing is the blocker, not key invalidity. For Google Cloud client libraries, check ADC/service-account env rather than assuming an API key exists. Treat committed real credentials as compromised even in private repos and recommend rotation plus env migration. See `references/repo-secret-validation-and-env-migration.md`.
- When a user asks what landed in recent/closed PRs, especially after they remember a branch name or package choice, inspect the PR body, changed files, and diff before answering. Branch names like `feat/mdx-write-mode` can be aspirational or stale; the implementation may still be CodeMirror/React Markdown/etc. Verify dependencies and imports (`package.json`, lockfile, active component path) before saying a package or architecture landed.
- When a user is approving/denying GitHub cleanup or PR-triage steps in chat, present **one approval item at a time**. After they approve, perform that action, verify it, then present the next item. If they ask for a full report, give the report but still end with a single clear approval/deny prompt rather than a stack of choices.
- For Semyon-facing PR-by-PR triage, do not dump the full queue unless asked. Pick one open PR, inspect its files/diff/checks/comments, then report in this compact order: `PR # / repo`, `MERGE` or `HOLD`, what it changes, risk/check caveats, and the exact reason for the verdict. Stop there and wait for the next approval/request.
- Before recommending merge for a tiny green PR, verify the change is actually needed, not merely harmless. Search current base for the supposed missing symbol/usage and compare against modern framework defaults; close stale/cargo-cult fixes rather than merging import/config noise just because CI is green.
- Before recommending merge for a tiny green PR, verify the change is actually needed, not merely harmless. Search current base for the supposed missing symbol/usage and compare against modern framework defaults; close stale/cargo-cult fixes rather than merging import/config noise just because CI is green.
- For stale/conflicted PRs that may be drift rather than real conflict, compare merge-base history and landed equivalent commits before recommending closure. Salvage the residual useful delta onto a fresh branch from current base when it applies cleanly. See `references/pr-drift-salvage.md`.
- For stale or machine-generated i18n PRs, never merge by file replacement. Preserve the current base keyset, verify placeholder parity, detect key-like/plural artifacts in values, and create a fresh cleanup PR when needed. See `references/stale-i18n-pr-cleanup.md`.
- For bot autofix PRs, separate the real underlying issue from the bot's implementation. Close stale/mixed autofixes when they bundle risky CSP/auth/routing/storage changes, and salvage only coherent pieces into human-authored PRs. See `references/bot-autofix-pr-triage.md`.
- After merging or closing superseded agent PRs, clean deprecated branches when they belong to the same repo and no longer carry useful state. If branch deletion fails because a local worktree owns the branch, remove the worktree first, then delete the local/remote branch and verify with `git ls-remote --heads`.
- When a PR has a failing CI job that appears unrelated to the PR diff, inspect the failing test's current assumptions before dismissing it as flaky. Look for recently-landed auth/session/schema/date assumptions, port the minimal test fix onto the PR branch, run the focused failing test locally, push, and watch the full latest CI run. Public UI E2E checks can also become stale after a deliberate copy/config change: compare the test locator with the rendered component's current accessible text or `mailto:` target, then update the assertion—not the production page—when the product value is intentional. Keep that correction as an isolated test-only commit/branch, particularly when the normal checkout contains unrelated WIP. If another deterministic job then fails, fix that too before reporting merge-readiness. For the Swim auth-session/date pattern, see `references/swim-ci-auth-session-e2e-date.md`.

## 5) Dependabot and Security Alerts

Use this when GitHub reports dependency vulnerabilities, especially after a push.

### Docker update configuration preservation

When adding Docker digest update automation, inspect any existing `.github/dependabot.yml` before writing. Do **not** replace established npm/pnpm/Cargo update policies with a tiny Docker-only file. Preserve existing entries exactly and append the needed `package-ecosystem: docker` entries for every directory that actually contains a Dockerfile. Validate the YAML and stage only that file. This matters especially in mature repos where Dependabot grouping, reviewers, cron cadence, and security policies are deliberate.

### Cross-repo simple dependency bump sweep

When Semyon asks to merge the simple/reasonable bump PRs across repos:

1. Enumerate candidates with `gh search prs --owner semyonfox --state open --json repository,number,title,author,isDraft,url`, filtering for Dependabot authors or titles containing bump/deps/dependencies/vulnerable.
2. For each candidate, inspect `state,isDraft,mergeStateStatus,baseRefName,headRefName,files,statusCheckRollup` before merging. Prefer only `OPEN`, non-draft, `CLEAN`, no failed/error checks, and package/lockfile-only diffs.
3. Treat CodeRabbit skipped/success and GitGuardian success as useful but not full CI. For active production-ish repos or auth/server-impacting changes, require real project CI or run equivalent checks before merging.
4. Skip PRs that are not pure dependency bumps, especially when a Dependabot branch also changes source/tests, auth middleware, API behavior, or configuration. Summarize why instead of silently merging.
5. Skip dependency PRs under raw archives/session dumps/device dumps unless the repo is explicitly meant to maintain those snapshots; these are usually cleanup candidates, not app dependencies.
6. After each merge in the same repo, re-check remaining PRs. GitHub may change later PRs from `CLEAN` to `UNKNOWN`/`DIRTY` after the base advances; do not keep merging based on the first scan.
7. For low-risk docs/housekeeping drafts that are clearly safe and requested by the user, it is acceptable to mark ready and merge after checks pass, but keep code/auth/runtime changes for explicit review.
8. Verify every merged PR with `gh pr view --json state,mergedAt,mergeCommit,url`; then report merged items and skipped blockers separately.

1. Query the actual alerts first, not the vague push banner:

```bash
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "/repos/$repo/dependabot/alerts?state=open&per_page=100" \
  | jq -r '.[] | "#\(.number) \(.security_vulnerability.severity) \(.security_vulnerability.package.ecosystem)/\(.security_vulnerability.package.name) \(.security_vulnerability.vulnerable_version_range) patched=\(.security_vulnerability.first_patched_version.identifier) manifest=\(.dependency.manifest_path)"'
```

2. Identify why the vulnerable package is present using the native package manager (`pnpm why <pkg>`, `npm explain <pkg>`, `cargo tree -i <crate>`, etc.).
3. Prefer upgrading the direct parent package. If the patched version is only needed transitively and the parent has not released yet, use the package manager’s supported override/resolution mechanism and document it in the commit.
4. Regenerate the lockfile with the project’s package manager. For pnpm: `corepack pnpm install` or `corepack pnpm install --lockfile-only` followed by a real install if you need to verify `pnpm why`.
5. Verify the resolved version is outside the vulnerable range (`pnpm why`, lockfile search, `cargo tree`, etc.). For pnpm transitive/peer-dependency alerts, a root `pnpm.overrides` entry may be the cleanest fix; regenerate the lockfile and explicitly grep for the vulnerable resolved package keys (for example `vite@7.3.2` or `@babel/core@7.29.0`) before pushing.
6. Run project checks/builds. If a post-push deploy is triggered, wait for CI/Jenkins and probe the live service. If a repo’s manual deploy script targets a stale server checkout/path while Jenkins is the real deployment path, fix the script to be a local verify/build helper (or remove the broken remote action) rather than preserving a misleading deploy command.
7. After pushing, poll Dependabot alerts again. GitHub usually refreshes quickly, but do not claim the banner is resolved until `gh api /dependabot/alerts?state=open` is empty or the relevant alert numbers are gone.

## 6) Issues and Triage

Use this section when the user wants issue creation, triage, labels, assignment, or closure.

Helpful sequence:

1. List open or untriaged issues.
2. Read the issue body and labels.
3. Categorize it as bug, feature, question, or maintenance.
4. Add labels and assignees.
5. Close or reopen only after the action is justified.

- For agent-discovered work, create issues only when the finding is concrete and evidence-backed. A good issue includes:

- problem or feature goal
- affected files/paths if known
- evidence: failing check, reproduction, or static trace through callers/callees/config/tests/data flow
- suggested direction
- acceptance criteria
- safety notes such as live API/data constraints

Avoid vague issues like "improve architecture" or "clean up code" unless there is a specific, bounded failure mode.

### Recurring repo-agent sweeps

For recurring autonomous repo sweeps, every run should produce at least one concrete outcome or a precise no-op reason:

- draft PR opened or updated
- concrete GitHub issue opened
- blocker with exact human decision/next command
- cleanup action taken or proposed
- explicit `no safe work found` with evidence

If existing PRs block mutation, still scan TODOs, failing checks, recent review comments, and repo-local affordances. Open proposal/issues only when they are actionable and evidence-backed; otherwise report the blocker instead of silently returning `NO_ACTION`.

When the repo-agent is wired to Hermes Kanban, treat Kanban as the private control plane and GitHub as the repo-facing record:

1. Create/update Kanban cards first for durable state: PR review gates, dirty-checkout blockers, cleanup candidates, and next targets.
2. Open GitHub issues only for concrete repo-visible findings (bug, feature request, security/privacy issue, CI/test gap, docs gap, dead-code cleanup). Keep dirty local checkouts, agent retries, and private workflow decisions Kanban-only.
3. Before creating an issue, search open and recently closed issues for the same finding/title/body keywords; prefer commenting/updating the existing issue/card over creating a duplicate. If a duplicate slips through, close it immediately with a clear duplicate note and block/archive the duplicate Kanban card.
4. Use stable idempotency keys for Kanban cards and link both directions: issue/PR body includes the Kanban task id; Kanban comments include issue/PR URLs.
5. For GitHub Projects v2, verify `gh` has `project`/`read:project` scopes first (`gh auth refresh -h github.com -s project -s read:project`). If missing, continue with issues/PRs/Kanban and leave a blocked Kanban card telling the human to run `gh auth refresh -h github.com -s project -s read:project`. If the user asks you to complete the auth and credentials live in Bitwarden, follow `references/github-cli-auth-refresh-with-bitwarden.md`: use the EU Bitwarden server if needed, keep one `bw login` OTP prompt alive instead of restarting and invalidating OTPs, retrieve the GitHub item/TOTP without printing secrets, authorize the GitHub device flow, verify scopes, then lock Bitwarden.
6. Report GitHub deltas explicitly in the cron digest: issues opened/closed, PRs opened/updated, project items added/skipped, Kanban cards created/reused, and duplicate cleanup.

When the user asks what the repo-agent is doing, whether it can self-fill work, or what is blocking its loop, inspect the durable job definition and recent report instead of answering from memory. Use `cronjob(action='list')` to identify the repo-agent job, read the job prompt/config and `/home/semyon/.hermes/repo-agent/reports/latest.json` when present, then distinguish **configured capability** from **observed recent behavior**. For issue discovery / feature creation questions, specifically check for phases or report fields covering issue scans, TODO/failing-check discovery, candidate selection, issues opened, experimental-feature lanes, blockers, and human actions needed. Keep the user-facing answer short and concrete, then continue one PR/blocker at a time.

When using GitHub with Hermes Kanban-backed repo-agent workflows:

- Treat **Kanban as the private agent control plane** and **GitHub as the repo-visible truth**. Kanban stores routing, blockers, dirty-checkout decisions, handoffs, and human gates; GitHub stores issues, feature requests, PRs, CI/review discussion, and project status.
- Open GitHub issues only for concrete, evidence-backed repo-visible work. Keep local-only blockers such as dirty checkouts, untracked personal files, agent retry noise, or “needs Semyon decision” cards in Kanban unless they reveal a real repo problem.
- Link every repo-agent-created issue/PR back to its Kanban task in the body/footer, and comment the GitHub URL back on the Kanban card.
- Use stable repo-agent labels: `repo-agent`, `agent-candidate`, `agent-generated`, `agent-needs-human`, `agent-blocked`, `agent-fix-ready`, `experimental-feature`, plus lane labels such as `deadcode`, `ci`, `tests`, `security`, `performance`.
For GitHub Projects v2, verify `gh` has `project`/`read:project` scopes first (`gh auth status`). If missing, continue with issues/PRs/Kanban and leave a Kanban setup blocker rather than failing the whole sweep. The repair command is `gh auth refresh -h github.com -s project -s read:project`; in headless/SSH sessions run it in a PTY/background process, capture the one-time device code, open `https://github.com/login/device` in a browser, then re-run `gh auth status` to verify the new scopes. Do not repeatedly guess GitHub/Bitwarden credentials during this flow; if credentials are needed, retrieve them through the user's approved password-manager path or stop for clarification to avoid lockouts.

When reviewing existing PRs, mine AI-review surfaces without treating them as mandatory gates. Fetch PR reviews, review comments, issue comments, and status contexts from known bots/reviewers such as `coderabbitai`, GitHub Copilot, Codex, Claude, Renovate, and Dependabot. Classify each item as actionable correctness/security/test issue, optional style/nit, stale/superseded, or skipped/no-review. If actionable and still valid against the current diff, either fix it in the PR branch, open/link an issue, or report it as human-action-needed.

Branch-naming/status-only failures should be separated from real checks. If a naming workflow rejects safe automation branches such as `agent/*`, prefer deleting or relaxing that workflow in a small isolated PR rather than renaming durable agent branches or treating the PR as functionally failing.

## 6b) Agentic Issue-to-PR Loop

### Independent-review merge gate

For user-authorized agent PR merges, use an independent high-depth reviewer after implementation and before promoting a draft. The reviewer must inspect the complete `origin/<base>...HEAD` diff, migrations, deployment/config changes, privacy/auth boundaries, and relevant test coverage, then return a concrete `MERGE` or `HOLD` verdict. Treat `HOLD` findings as real engineering work, not advisory noise:

1. Fix each concrete blocker in the isolated PR worktree.
2. Run focused verification for the fix and amend/push the branch.
3. Require a fresh independent review after the fix; do not reuse the earlier approval.
4. Re-check live GitHub checks and merge state immediately before `gh pr ready` / `gh pr merge`.
5. If a local worktree prevents `gh pr merge` because its base is checked out elsewhere, retry from a neutral directory with `--repo owner/repo`.

A review gate is especially valuable for analytics/privacy changes: verify delayed workers cannot bypass a request-bound privacy signal, public event fields have a closed/sanitized schema, retention documentation matches the actual database purge function, and build-time client flags are propagated through Docker/CI.

When using Codex/Claude/Hermes to automate issue-to-PR work, keep GitHub operations outside the coding agent where practical:

1. Use shell/`gh` to read the issue/PR, create the branch/worktree, push `agent/*`, open/update draft PRs, and apply labels.
2. Use Codex for the scoped implementation or review inside the isolated worktree.
3. Run checks outside Codex when possible; pass concise failure summaries back for one bounded retry.
4. Use an independent review context before pushing/opening a draft PR. For high-risk changes, get a cross-model second opinion such as Claude Code in read-only/planning mode.
5. Never auto-merge. Draft PRs should clearly state that the user must approve/merge.

Handoffs between stages should be compact task cards, not transcripts: repo, issue/PR, goal, attempted approach, affected files, commands/checks run, verdict, blocker, and next action.

## 7) Common Pitfalls

- Treating `gh` installation as proof of auth
- Using the wrong repo owner/name when the remote is indirect or SSH-based
- Reviewing PRs without checking the base branch or changed files first
- Forgetting that GitHub returns PRs in the issues endpoint too
- Posting broad comments when an inline review would be clearer
- Skipping CI verification before merge
- Treating the Dependabot push banner as current state after a fix; query alerts directly after GitHub refreshes.
- Fixing lockfile-only vulnerabilities without verifying the resolved dependency graph (`pnpm why`, `npm explain`, `cargo tree`, etc.).

## 8) Verification Checklist

- [ ] Auth path identified
- [ ] Repo/owner resolved correctly
- [ ] Correct GitHub surface chosen (`gh` vs REST)
- [ ] Change reviewed or issue triaged with concrete evidence
- [ ] For dirty working trees, local uncommitted changes vs commits-ahead-of-remote were classified explicitly
- [ ] Staged files were selected deliberately and checked for obvious secrets
- [ ] Project-native checks/builds ran, or a CI/Docker-equivalent verifier was used
- [ ] CI/merge/deploy outcome verified when relevant
- [ ] For Dependabot work, open alerts were queried before and after the fix, and the resolved dependency graph was verified.

## 9) Support files

- `references/dependabot-alerts.md` captures the alert query → dependency graph trace → override/upgrade → lockfile/check/build → post-push alert verification workflow.
- `references/dirty-working-tree-push.md` captures the checklist for pushing uncommitted local work safely: classify local-vs-remote state, stage exact files, secret-scan staged changes, verify with Docker/CI-equivalent builds if needed, and wait for post-push deploy jobs.
- `references/multi-agent-dev-integration.md` captures the clean-worktree pattern for integrating several local agent branches into `dev`: ordered cherry-picks, conflict curation, focused/full checks, visual smoke tests, guarded push, CI/deploy verification, and concise reporting.
- `references/dirty-dev-bundle-push-and-worktree-cleanup.md` captures the dirty integration-branch variant: safety branch, staged secret scan, rebase conflict policy that preserves newer remote architecture, tests/build, exact remote SHA verification, live deploy probe, and cautious old-worktree cleanup.
- `references/dirty-repo-data-classification.md` captures dirty-repo triage for mixed source/data/private artifacts: encrypted-vs-plaintext SQLite checks, reachable-history DB header scans, and personal experiment exclusion before PRs.
- `references/jj-dirty-worktree-to-pr.md` captures the jj-colocated variant: inspect with jj, rebase/describe/bookmark, push the bookmark, open a non-draft PR to the lowest integration branch, then `jj new <base>` to park the main worktree cleanly.
- `references/repo-agent-recurring-sweeps.md` captures recurring repo-agent sweep practices: branch-naming noise, conflict summaries, dirty-state preservation, AI review mining, and minimum useful per-run outcomes.
- `references/repo-agent-kanban-github-sync.md` captures the Kanban ↔ GitHub Issues/PRs/Projects sync pattern for recurring repo-agent sweeps, including idempotency keys, duplicate issue guards, and Project v2 scope handling.
- `references/github-cli-auth-refresh-with-bitwarden.md` captures the Bitwarden-assisted `gh auth refresh` workflow for adding GitHub Project scopes, including EU vault config, new-device OTP handling without invalidating codes, GitHub TOTP retrieval, scope verification, and cleanup.
- `references/pr-drift-salvage.md` captures the stale/conflicted PR salvage pattern: identify already-landed equivalent work, apply only the residual useful delta to current base, and report keep/skip/change choices clearly.
- `references/bot-autofix-pr-review.md` captures how to review CodeRabbit/Copilot-style autofix PRs: verify current-base context, reject unsafe bundled config/UX changes, and salvage only real issues into human-authored PRs.
- `references/cross-repo-agent-cleanup.md` captures cross-repo repo-agent hygiene: classify dirty repos, remove stale worktrees/branches after merged/closed PRs, and report one next action.
- `references/cross-repo-pr-inventory.md` captures the quick "what's left?" workflow: global `gh search prs` inventory, target-repo PR summaries, check-status triage, and merge-suitability caveats for draft, label-only, main-vs-dev, auth/API, and mixed Dependabot PRs.
- `references/stale-i18n-pr-cleanup.md` captures safe handling for stale or machine-generated translation PRs: preserve current keysets/placeholders, detect key-like/plural artifacts, and prefer safe English fallbacks over broken localized UI.
- `references/bot-autofix-pr-triage.md` captures how to mine CodeRabbit/Copilot/autofix PRs for real issues without merging mixed risky bot patches blindly, especially CSP/auth/routing changes.
- `references/security-sensitive-pr-review.md` captures the security-sensitive PR review pattern: generic public errors, detailed internal logs/metrics, and tests for both sides.
- `references/repo-secret-validation-and-env-migration.md` captures safe private-repo API-key validation, distinguishing auth-valid vs operation-usable vs locally configured credentials, and env/rotation migration guidance.
- `references/pr-triage-and-safe-bump-sweeps.md` captures Semyon-facing one-at-a-time PR triage and conservative rules for merging simple dependency-bump sweeps.
- `references/repo-agent-draft-pr-unblock-sweep.md` captures bulk repo-agent draft PR unblock sweeps: live PR/check inventory, Claude second-opinion as advisory, local temp-worktree verification for bot-only checks, safe draft promotion/merge, and dirty/local-only blocker salvage into draft PRs.
- `references/bulk-repo-agent-pr-closer.md` captures the broader bulk closer/opener pass for managed repo-agent queues: merge safe drafts, locally verify bot-only PRs, salvage stale duplicate PRs into fresh replacement PRs, close broad dirty blockers, and rerun the repo-agent job afterward.
- `references/swim-ci-auth-session-e2e-date.md` captures a Swim CI debugging pattern: DB-backed auth middleware tests need active refresh sessions, and seeded UI E2E tests may need browser date freezing when fixture dates are historical.
- `references/private-forks-and-career-artifacts.md` captures private-fork boundaries, career/CV repo hygiene, public portfolio CV asset handling, and encrypted DB checks before committing PII-adjacent files.
