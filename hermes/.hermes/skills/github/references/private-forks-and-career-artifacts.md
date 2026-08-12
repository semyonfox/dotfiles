# Private forks and career artifacts

Use this when dirty local work contains personal materials, private workflow forks, or changes aimed at Semyon's own infrastructure rather than upstream/open-source contribution.

## Private performance forks

- If Semyon says a fork is for his workflow only, treat it as a private/local fork target, not an upstream contribution target.
- For `marker++` specifically: it is Semyon's private Marker performance fork for Oghma/workflow needs. Do not open PRs to `datalab-to/marker` unless Semyon explicitly reverses that decision.
- Preserve useful perf/profiling changes on Semyon's branch/fork; verify with local tests and document usage, but avoid upstream PR framing.

## Career/CV repos

- Specific job applications, cover letters, and company-targeted CVs should live in a private repo.
- Public website should expose only a generic CV asset, normally `/cv.pdf`; if source is useful to expose, serve a generic `/cv.tex` beside it.
- Verify repo visibility with `gh repo view owner/repo --json visibility,isPrivate,url` before pushing personal application materials.
- For a public portfolio site, copy only the generic CV source/PDF from the private CV repo; avoid company-specific filenames or application text.
- When adding public CV downloads to the portfolio, verify the local public assets match the private generic source/PDF by hash, not just filename. Check the live `/cv`, `/cv.pdf`, `/cv.tex`, and `/cv.md` endpoints after Jenkins/deploy, and browser-test any format selector.

## Jenkins-owned portfolio deployment

- For Semyon's portfolio, the canonical source is `/home/semyon/code/personal/portfolio` on local/Hermes and `origin/main` on GitHub. Jenkins owns production deploy on push.
- Do not rely on stale manual shortcuts that SSH to `~/portfolio` on the server; that path may not be a git checkout. If a manual deploy script exists, make it a local verifier (`check` + `build`) or update it to the real Jenkins/stack flow.
- After pushing portfolio changes, verify Jenkins saw the GitHub push, wait for the numbered portfolio build to finish, and then probe the live site and key assets.
- Treat GitHub Dependabot push banners as provisional. Query alerts with `gh api /repos/<owner>/<repo>/dependabot/alerts?state=open` after the push and dependency graph refresh before saying alerts are fixed.

## Sensitive local databases in dirty repos

- Before committing tracked DB files that contain or may contain PII, verify whether the current and historical reachable blobs are encrypted/plaintext.
- A plaintext SQLite file starts with `SQLite format 3\0`; SQLCipher/encrypted files should not.
- Check reachable git history with `git rev-list --all -- <db>` and inspect unique blobs' first bytes with `git cat-file -p <blob> | head -c 16` or an equivalent binary-safe script.
- Do not commit plaintext backups, master keys, generated audit output, or local `.env` files. Commit source/tests only, and update `.gitignore` if needed.
