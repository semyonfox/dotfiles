# Recruiter-facing GitHub profile and README refresh

Use when Semyon wants a GitHub profile/readme pass to support internship or placement applications.

## Goal

Make a 30-second reviewer path:

1. Profile README says the target role/placement window and links to the portfolio/CV.
2. Pinned repositories show distinct, defensible evidence rather than generic configuration or stale hobby descriptions.
3. Each pinned repo README answers: **what it is → system shape → engineering decisions → how it is verified → scope/limitations**.

## Discovery

- Query the actual pinned repos with GraphQL before choosing scope; do not assume the previous pin set.
- Inspect each repository’s current README, root docs/configuration, tests/CI, and any `AGENTS.md` before writing claims.
- Use clean temporary clones/worktrees for public README work when local project checkouts may contain unrelated WIP.
- Inspect the user’s profile README separately: it is its own repository (`<username>/<username>`) and commonly becomes stale sooner than the portfolio site.

## Writing rules

- Lead with a one-sentence technical problem and compact architecture, not a long skills list or product marketing.
- Use evidence-backed verbs: `implements`, `defines`, `includes`, `is configured to`, `documents`.
- Keep ownership truthful. For a team-originated project, retain visible project provenance and describe Semyon’s contribution only where evidence supports it.
- Separate implemented code from live runtime claims. Do not turn Docker/Jenkins/CI configuration into claims of uptime, production readiness, passing CI, paid users, throughput, or scale without fresh verification.
- For security-sensitive integrations, state actual authorization and deployment boundaries. Do not call a broad/mutating tool surface "safe" merely because the downstream API also authorizes requests.
- Remove stale pricing, provider, architecture, or deployment claims instead of preserving a flashy but contradictory README.
- A small non-systems project is fine when pinned; describe it accurately rather than forcing a platform/SRE narrative.

## Push and verification

For each repo:

1. Fetch and confirm the local base equals the remote default branch (do not assume it is named `main`; resolve `origin/HEAD`).
2. Stage only `README.md`.
3. Run `git diff --cached --check` and a lightweight staged secret scan.
4. Run the narrowest relevant project check where dependencies are already available; Markdown-only changes do not justify modifying unrelated source/configuration to repair a pre-existing gate.
5. Commit each repository independently with a clear docs message, push to its actual default branch, and verify the remote SHA with `git ls-remote`.

## CV relation

Do not rewrite a generic CV solely because the public profile changed. Locate the private/local CV repository, preserve its dirty role-specific drafts, and compare the exact CV and job description from the relevant application before proposing a targeted edit.
