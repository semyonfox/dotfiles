# Dependabot alert workflow

Use for GitHub push banners like “GitHub found N vulnerabilities” or when asked to investigate Dependabot.

## Query alerts

```bash
repo=$(gh repo view --json nameWithOwner -q .nameWithOwner)
gh api "/repos/$repo/dependabot/alerts?state=open&per_page=100" \
  | jq -r '.[] | "#\(.number) \(.security_vulnerability.severity) \(.security_vulnerability.package.ecosystem)/\(.security_vulnerability.package.name) range=\(.security_vulnerability.vulnerable_version_range) patched=\(.security_vulnerability.first_patched_version.identifier) manifest=\(.dependency.manifest_path) url=\(.html_url)"'
```

The push banner can remain stale for a moment. Trust the Dependabot alerts API after push, not the old banner text.

## Trace dependency source

Use the package manager’s graph command:

- pnpm: `corepack pnpm why <package>`
- npm: `npm explain <package>`
- yarn: `yarn why <package>`
- Cargo: `cargo tree -i <crate>`

## Fix strategy

1. Prefer upgrading the direct parent package if a normal semver upgrade resolves the vulnerable transitive.
2. If the parent has not yet released or a broad framework upgrade is unnecessary, use the package manager’s override/resolution mechanism.
3. Regenerate the lockfile with the project package manager.
4. Install, then verify the resolved graph, not just the lockfile diff.

Example pnpm override for a transitive package:

```json
"pnpm": {
  "overrides": {
    "esbuild": "^0.28.1"
  }
}
```

Then:

```bash
corepack pnpm install
corepack pnpm why esbuild
corepack pnpm run check
corepack pnpm run build
```

## Push and verify

After commit/push:

```bash
gh api "/repos/$repo/dependabot/alerts?state=open&per_page=100" | jq length
```

If the repo triggers Jenkins/CI/deploy, wait for it and probe the deployed service before finalizing.
