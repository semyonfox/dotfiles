# Archive delivery checklist

Use this when the user wants repo content or a vault exported as a zip. For Obsidian vaults and chat/Discord delivery edge cases, also consult `productivity` → `references/obsidian-vault-export-delivery.md`.

## Scope check
- Clone or fetch the repo first.
- Determine whether the requested content lives inside the repo or exists as separate local media.
- If the ask mentions transcripts, videos, or other assets, search for them explicitly rather than assuming they are part of the markdown export.

## Packaging
- Prefer ZIP when the recipient is non-technical or explicitly asks for a zip.
- Preserve the repo-relative path structure inside the archive so the bundle is easy to unpack.
- If `zip` is missing, use a portable ZIP creator such as Python's `zipfile` module.

## Verification
- Inspect the archive contents after creation.
- Confirm the archive contains the intended folder/file set.
- If only notes were found but media/transcripts were not, say so plainly.
