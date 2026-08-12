# Canvas CA vs official results analysis

Use this when Semyon asks whether an official module result matches how the coursework/exam felt, or asks for a breakdown/profile from Canvas + the official results portal.

## Goal

Compare official portal finals with Canvas-visible CA/submission data, then separate:

- official facts: final mark, credits, classification/result text from the results portal
- Canvas-visible facts: assignment scores, assignment groups, group weights, provisional/overall items, announcements
- inferred estimates: implied exam marks or hidden-component marks reverse-engineered from known weights

Do not present inferred exam marks as official unless Canvas explicitly shows an `Exam`, `Overall`, `Provisional Mark`, or similar item.

## Data collection pattern

1. Pull official results from the results portal watcher/cache or authenticated portal flow.
2. Pull Canvas courses for active and completed terms.
3. For each relevant module, collect:
   - course metadata and term
   - enrollments/total scores if exposed
   - assignment groups with weights
   - assignments including submissions
   - announcements containing grade/mark/overall/provisional/exam/CA/weight/result keywords
4. Match Canvas course codes to official module codes, normalizing prefixes like `2526-CT230` -> `CT230`.
5. Build a compact per-module table: official mark, visible CA, explicit Canvas final/provisional mark, known weights, inferred exam/hidden component where possible.

## Useful calculations

Weighted reverse-engineering:

```text
final = ca_weight * ca + exam_weight * exam
exam = (final - ca_weight * ca) / exam_weight
```

When Canvas gives exact components, report them directly. Example: if Canvas shows `CA=99`, `Exam=50`, `Overall=60`, and an announcement says `20:80`, say the exam mark is visible, not inferred.

When Canvas only shows CA and the official final, label the estimate:

```text
visible CA 84.6%, official final 62%, weights 30/70 -> implied exam ≈52.3%
```

If weights are absent, avoid inventing a split. Say the visible coursework was higher/lower than the official final and that an unseen/hidden exam or moderation component likely explains the difference.

## Interpretation pattern

Semyon wants a compact but blunt read:

- start with the headline: whether the feeling was justified
- identify practical/coursework strength vs exam-conversion weakness
- cite only enough numbers to support the conclusion
- avoid giant raw dumps of every assignment unless asked

Good phrasing:

> You’re not delusional: Canvas-visible coursework was much stronger than several official finals. The profile is strong practical/coursework performance, weaker exam conversion.

## Pitfalls

- Canvas group weights can be `0` or absent even when marks exist; treat that as insufficient weighting evidence.
- Some provisional/final Canvas items have `points_possible=0` and `omit_from_final_grade=true`; they can still be official/provisional marks if explicitly named `Provisional Mark`, but should not be included in CA averages.
- Sample/practice MCQs can pollute CA averages. Exclude names containing `sample`, `practice`, or obvious non-counting items unless the user asks for all visible scores.
- Announcements often contain the only reliable weighting note. Search announcements before reverse-engineering.
- Keep student IDs, tokens, and raw auth material out of the response. Report module codes and marks only.
