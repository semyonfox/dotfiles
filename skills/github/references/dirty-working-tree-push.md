# Dirty Working Tree Push Checklist

Use when the user authorizes pushing local work that exists as uncommitted changes rather than commits ahead of GitHub.

## Classify first

```bash
git fetch --quiet origin main || true
git status --short --branch
git log --oneline --decorate --left-right --cherry-pick origin/main...HEAD
git diff --stat
git ls-files --others --exclude-standard
```

If `origin/main...HEAD` is empty but `git status` is dirty, the work is not “ahead of GitHub” yet; it is uncommitted local state.

## Pre-commit safety

- Inspect changed file list and diff stat.
- Summarize what is being committed in human terms.
- Stage exact files only; avoid `git add .` in repos likely to contain local `.env`, backup, database, or generated files.
- Run a staged secret scan. Example shape:

```bash
git diff --cached --name-only | while read -r f; do
  case "$f" in *.lock|Cargo.lock) continue ;; esac
  grep -InE 'TUNNEL_TOKEN\s*=\s*[^$]|API_KEY\s*=|SECRET\s*=|PASSWORD\s*=|sk-[A-Za-z0-9]{12,}|gho_|GOCSPX|AKIA[0-9A-Z]{16}' "$f" || true
done
```

Tune the pattern to avoid lockfile false positives, but keep scanning source/config files.

## Verification before push

Run project-native checks/builds. If a local compiler/package manager is missing, prefer a project Docker build or CI-equivalent command rather than stopping at `command not found`.

Examples:

```bash
corepack pnpm run check
corepack pnpm run build
docker compose build <service>
```

If a dependency version fails only in the Docker/CI build, fix the durable compatibility problem before pushing.

## After push

```bash
git push origin main
git status --short --branch
git log -1 --oneline
```

If the push triggers CI/Jenkins/deploy, wait for completion and verify live behavior. Do not report success from the push alone when deployment is part of the user’s request.
