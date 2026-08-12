---
name: git-history-rewriting
description: Safely remove sensitive files or secrets from Git history, verify all reachable refs, and coordinate GitHub cleanup.
version: 1.0.0

metadata:
  harness: [hermes]
---

# Git History Rewriting

Use when a repository needs a destructive history rewrite: accidental secret/config commits, oversized/generated artifacts, or legally/privacy-sensitive files. This is a high-impact workflow: a deleted file on the default branch is **not** a completed historical purge.

## Scope and safety

1. Determine whether the artifact carries a confirmed secret, placeholder, ordinary config, or only sensitive-looking metadata. Inspect locally without printing values, hashes, or tokens into chat/issues.
2. Identify the repository owner, default branch, branch protection, all heads/tags, open PRs, and whether the primary checkout has uncommitted or local-only work.
3. Do not rewrite a dirty or locally divergent primary checkout. Create a fresh `git clone --mirror` for the rewrite. Preserve real local-only work separately before any destructive reset/reclone.
4. Before a rewrite, land prevention where feasible: remove the tracked file at the tip, add a placeholder-only example, ignore the real path, document the secret-store/deployment path, and add a repository guard.
5. Make a verified, access-restricted local rollback bundle only for the rewrite window. Never push it to a remote. Delete it after remote verification if the cleanup goal requires removing the artifact from local copies too.

## BFG workflow

1. Clone a fresh mirror after the prevention change is merged:
   ```bash
   git clone --mirror git@github.com:OWNER/REPO.git repo.git
   ```
2. Run BFG with the exact basename/path policy. For an exact filename:
   ```bash
   bfg --delete-files .env.production repo.git
   git -C repo.git reflog expire --expire=now --all
   git -C repo.git gc --prune=now --aggressive
   ```
3. Verify **before pushing**:
   ```bash
   git -C repo.git rev-list --all --objects | awk '$2==".env.production"{n++} END{print n+0}'
   # Expect 0
   ```
   Also test every rewritten ref with `git cat-file -e <ref>:<path>`; none may contain the target.
4. A mirror clone normally sets `remote.origin.mirror=true`. Use explicit non-mirror push configuration for the mutable GitHub refs:
   ```bash
   git -C repo.git -c remote.origin.mirror=false push origin --force --all
   git -C repo.git -c remote.origin.mirror=false push origin --force --tags
   ```
   Do not blindly use `--mirror` against GitHub: it can include refs that should never be mutated.

## GitHub PR-ref limitation

A successful force-push of all branches and tags is not always a complete GitHub purge.

- Fresh-clone the remote after pushing and verify every advertised ref, including `refs/pull/*`, rather than checking only branches.
- GitHub retains immutable pull-request refs for old/closed PRs. Attempts to update them are rejected with `deny updating a hidden ref`.
- If the target is still reachable solely through `refs/pull/*`, report: mutable branch/tag history was rewritten, but GitHub-hosted PR refs remain. A GitHub Support sensitive-data/history-removal request is required for a full server-side purge.
- Do not claim “history fully cleaned” until a post-push fresh mirror reports zero target paths across **all** refs.

## Post-rewrite verification and handoff

1. Fresh-clone the remote mirror.
2. Run `git fsck --full --no-reflogs` and the all-ref path checks.
3. Confirm the default branch has the safe template/prevention controls and does not contain the real file.
4. Tell collaborators not to push old clones. They should fresh-clone, or preserve/rebase/cherry-pick genuinely local work onto rewritten history deliberately.
5. Close/update the tracking issue only with an accurate status. If immutable GitHub PR refs remain, leave a clear blocker rather than falsely declaring the purge complete.
6. Remove the temporary BFG mirror, verification clone, downloaded tooling, and rollback bundle created for the operation once the verified outcome is recorded.

## Common pitfalls

- Treating a file named `.env.production` as proof that a live secret leaked. Audit safely first.
- Merging a deletion without rewriting older commits.
- Checking `refs/heads` only and missing `refs/pull/*`.
- Trying to force-push GitHub hidden PR refs.
- Resetting a normal working checkout that contains unpublished work.
- Retaining a pre-rewrite bundle or old clone after saying the local artifact has been purged.
