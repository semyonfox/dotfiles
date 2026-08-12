# University of Galway Digitary / results documents workflow

Use when Semyon is trying to access University of Galway results/transcripts through Digitary/Parchment, or sends official transcript / University Skills Passport PDFs.

## Key distinction

- **Live/current exam results** are published through University of Galway results pages / `regexam.nuigalway.ie` links.
- **Digitary / Parchment** is mainly the official document/transcript platform. Transcripts may appear there after marks are released, often after a delay.
- If Semyon says the Digitary results link is broken, first separate: "trying to see live marks" vs "trying to retrieve official transcript PDF".

## Browser/SAML troubleshooting pattern

For `core.digitary.net` failures, especially frontend messages like **"Uh-Oh!! We are unable to load the application"**:

1. Try an incognito/private window.
2. Disable privacy shields/adblock/script blockers for `core.digitary.net`.
3. Hard refresh (`Ctrl+Shift+R`).
4. Clear site data for:
   - `core.digitary.net`
   - `digitary.net`
   - `nuigalway.ie`
   - `universityofgalway.ie`
   - `login.microsoftonline.com`
5. Try the generic institutional entry point: `https://core.digitary.net/user/shibboleth`.
6. If the goal is live marks, redirect to the current University results page/link instead of over-focusing on Digitary.

Do **not** persist a claim that Brave/Zen/Digitary is generally broken. Treat browser failures as likely cookies/shields/session state unless reproduced broadly.

## PDF extraction workflow

When Semyon uploads official transcript / USP PDFs:

1. Extract text yourself; do not ask him to paste it.
2. Prefer `pdftotext -layout` if available because these PDFs are structured tables.
3. Check PDF metadata/pages with `pdfinfo` if needed, but do not expose private IDs/addresses unnecessarily in the final reply.
4. Parse and report:
   - year/session
   - overall result/classification
   - module marks and pass/compensation status
   - strongest/weakest modules
   - obvious query targets
5. If comparing years, calculate weighted averages by credits and call out credit-weighted effects, e.g. one 5-credit weak module vs a 10-credit strong module.

## Reporting style for Semyon

Start with the blunt verdict, then table/detail:

- "You passed / classification is X."
- "The sore thumb is Y."
- "Worth querying: A, B, C; recheck only after breakdown/consultation."

Avoid moralising a low module mark. Distinguish practical/software strength from formal exam/statistics weaknesses.
