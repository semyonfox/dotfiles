# i18n localization cleanup and stale translation PR salvage

Use when a localization PR is stale, machine-generated, or changing many locale JSON files.

## Safe approach

1. **Do not merge stale locale branches directly.** First compare the PR key count and current base key count. If the PR has fewer keys than current base, direct merge risks dropping newer UI strings.
2. **Preserve the current base keyset.** Start from current `origin/<base>` and apply only safe value cleanups; never replace whole locale files from an old branch.
3. **Validate invariants beyond the repo's normal i18n audit.** Built-in audits often catch missing keys/placeholders but miss key-like values in translations.
4. **Prefer safe fallback over broken translation.** If a machine translation mangled an internal key, plural suffix, or placeholder, use the English/base fallback rather than showing broken key text in the UI.
5. **Keep old PRs as superseded, not merged.** Open a fresh PR from current base and comment on/close the stale PR.

## Invariants to check

For every locale file:

- Keyset exactly matches base locale.
- Placeholder sets match the base string, e.g. `{count}`, `{summary}`, `{correct}`, `{total}`.
- No values are obvious translation-key artifacts such as `assignments.due_in_days_one`, `Canvas.import.Complete_one`, or `chat.about_context_contextPrefix`.
- No plural suffix garbage appears in displayed text, e.g. `_one` / `_other` appended to copied keys.
- JSON formatting stays stable and deterministic.

## Useful commands

```bash
# Compare key counts quickly
node - <<'NODE'
const fs = require('fs');
for (const f of fs.readdirSync('src/locales').filter(f => f.endsWith('.json'))) {
  const j = JSON.parse(fs.readFileSync(`src/locales/${f}`, 'utf8'));
  console.log(f, Object.keys(j).length);
}
NODE

# Run project i18n checks
npm run i18n:full-audit
```

## Reporting to Semyon

State clearly whether the result increases translation quality or only cleans unsafe artifacts. English fallbacks are acceptable when the alternative is broken key-like machine translation, but call that tradeoff out explicitly.