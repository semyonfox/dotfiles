# Cross-repo PR inventory and quick triage

Use this when Semyon asks what PRs are left across repos, asks about a named repo such as Swim after clearing another repo, or wants a quick merge queue rather than a full code review.

## Discovery

1. Start with a global open-PR inventory, not the last repo you touched:

```bash
gh search prs --owner semyonfox --state open --limit 100 \
  --json repository,number,title,isDraft,author,url,updatedAt \
  | jq -r 'group_by(.repository.nameWithOwner)[] | "\(.[0].repository.nameWithOwner)\t\(length)\t" + (map("#\(.number) " + .title) | join(" | "))'
```

2. If the user names a repo or domain, list that repo's PRs with PR metadata and checks:

```bash
gh pr list --repo semyonfox/<repo> --state open --limit 100 \
  --json number,title,author,headRefName,baseRefName,isDraft,mergeStateStatus,reviewDecision,updatedAt,url,additions,deletions,changedFiles
```

3. Prefer active/current-priority repos first: Oghma, Swim, SchoolBooks, browser extensions, active `semyonfox/*` projects. Do not spend review time on archived templates, coursework, CV, infra, external clones, or inactive/deprecated experiments unless explicitly asked.

## Per-PR quick triage

For each PR in the target repo, collect:

```bash
gh pr view <n> --repo semyonfox/<repo> \
  --json number,title,body,state,isDraft,mergeStateStatus,reviewDecision,baseRefName,headRefName,author,additions,deletions,changedFiles,files,statusCheckRollup,url,updatedAt

gh pr checks <n> --repo semyonfox/<repo> --watch=false || true

gh pr diff <n> --repo semyonfox/<repo> --patch --color never | sed -n '1,220p'
```

Also mine review/comment surfaces when deciding whether a bot or AI review created actionable blockers:

```bash
gh api repos/semyonfox/<repo>/pulls/<n>/reviews --jq '.[] | {user:.user.login,state,body,submitted_at}'
gh api repos/semyonfox/<repo>/issues/<n>/comments --jq '.[] | {user:.user.login,body,created_at}'
```

## Merge-suitability rules

- Do not treat label-only, CodeRabbit-skipped, or GitGuardian-only statuses as enough for merge when the PR touches runtime behavior, auth, authorization, data writes, migrations, or API contracts. Require real project CI or run the relevant tests locally.
- Draft PRs can be marked ready and merged only after the user explicitly approves and real checks are adequate.
- If a PR targets `main` but the repo's normal flow is `dev -> main`, flag the base-branch mismatch before recommending merge.
- Dependabot PRs with non-lockfile/source/test changes pushed into the branch are not pure dependency bumps; inspect those changes explicitly before recommending merge.
- Failed real checks block merge even when the code change looks correct. Report the failing check name and whether the change is otherwise worth salvaging.

## Reporting format

Keep the report compact:

- total open PRs across repos
- target repo PRs first, one PR at a time
- for each PR: what changed, files touched, check status, risk, verdict
- end with a recommended priority order, not a giant approval stack
