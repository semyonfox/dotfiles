# LMS grade monitoring and breakdowns

Use this when Semyon asks for Canvas/LMS grades, module results, CA/exam breakdowns, or honours/classification estimates.

## Workflow

1. **Find the canonical LMS data source first.** Prefer a maintained integration/token already in Semyon's systems over browser login. For Canvas, the REST API is usually more reliable than scraping the gradebook UI.
2. **Collect all relevant course surfaces:**
   - courses/enrollments for active and completed terms
   - assignment groups and group weights
   - assignments with `include[]=submission`
   - announcements/discussion topics, filtered for words like `grade`, `mark`, `overall`, `CA`, `exam`, `weight`, `provisional`, `result`
   - files/module PDFs where available, especially module overview, assessment info, exam summary, sample solutions, and rubric documents; use them to confirm weights when Canvas assignment groups are unweighted or incomplete
3. **Identify final/provisional marks conservatively.** Canvas often exposes final results as assignments named `Provisional Mark`, `Overall`, `Final`, or similar. Treat these as final/provisional only when explicitly named; do not infer an official result from ordinary assignment averages.
4. **Deduce component splits only when weights are visible or announced.** Use assignment group weights, announcements, and module/exam PDFs as evidence. Show the equation when reverse-engineering an exam mark from final + CA.
5. **Separate visible facts from inferred estimates.** Label unknown modules clearly; do not fill gaps with guessed exam weights except as explicit what-if baselines.
6. **For Semyon, include forensic failure-mode analysis.** He wants to know what likely went wrong, not just the average. For each module, compare official final vs visible CA and identify the most likely bucket:
   - rubric/style mismatch (e.g. practical/production-quality answer not matching lecture-note canonical answer)
   - brittle tooling/compile cliff (e.g. BlueJ/no-autocomplete lab exams where one typo breaks compile/run marks)
   - rote-recall exam ritual (sorting pseudocode, manual traces, definitions)
   - time pressure
   - hidden/unexplained final component that needs a breakdown request
   - genuine weak foundation needing repair (often stats/formal maths)
7. **Compute classification using the visible official/provisional finals first.** If some modules are missing, give:
   - current average over visible finals
   - required average on missing modules for each band
   - caveat that the official year/honours result depends on equal/credit weighting and the missing marks
8. **Recommend query/recheck actions selectively.** Consultation is for understanding results and seeing breakdown/scripts; a recheck is arithmetic/transcription only and does not re-mark content. Flag modules worth querying when visible CA and official final diverge sharply, Canvas lacks the hidden component, or the user’s exam account suggests a plausible marking/rubric issue.
9. **If results are expected today, add a short-lived watcher.** A `no_agent` cron/script is ideal: keep prior state, poll Canvas, stay silent when unchanged, and report only deltas.

## Canvas API endpoints/patterns

- `GET /api/v1/courses?enrollment_state=active|completed&include[]=term&include[]=total_scores`
- `GET /api/v1/users/self/enrollments?state[]=active|completed|invited|inactive`
- `GET /api/v1/courses/{course_id}/assignments?include[]=submission`
- `GET /api/v1/courses/{course_id}/assignment_groups?include[]=assignments`
- `GET /api/v1/courses/{course_id}/discussion_topics?only_announcements=true`

When using a stored app token, avoid printing secrets. It is fine to decrypt/use a token locally when the user has explicitly asked for their grades and the token is already their own stored integration credential. Report only grades/results, not tokens or raw secret material.

## Calculations

Classification bands used in Irish/UK-style honours reporting:

- `>= 70`: 1st / First Class Honours
- `>= 60`: 2:1 / Second Class Honours Grade 1
- `>= 50`: 2:2 / Second Class Honours Grade 2
- `>= 40`: 3rd/pass
- `< 40`: fail

Reverse-engineering example:

```text
final = weight_ca * ca + weight_exam * exam
exam = (final - weight_ca * ca) / weight_exam
```

For missing equal-weighted modules:

```text
required_missing_average = (target_average * total_modules - sum(known_finals)) / missing_modules
```

### Deep Canvas grade investigations

When Semyon thinks an official/provisional final is too low, go beyond the gradebook average before interpreting it:

1. **Verify the official module weight from course materials**, not assumptions. Many modules are 70/30, but individual modules can be 80/20 or 60/40. Canvas assignment groups may show `0` weights even when a PDF/module overview states the real weighting.
2. **Pull context surfaces as evidence:** assignment groups, assignments with submissions, quizzes/submissions, announcements, files, modules, and pages. Search file names and announcement text for `assessment`, `exam`, `mark`, `weight`, `MCQ`, `provisional`, `summary`, `module overview`, and `exam info`.
3. **Download likely PDFs from Canvas files** and run `pdftotext` locally. Module overview / summary-and-exam-info PDFs often contain the real CA/exam split and exam format when Canvas groups do not.
4. **Separate actual CA from samples/practice.** Ignore `SAMPLE`, surveys, muted practice attempts, and `omit_from_final_grade` provisional totals unless they are explicitly the official final. Keep actual quizzes/labs/assignments only.
5. **Compute visible CA and implied exam mark.** Show the equation in the answer so the user can see whether a low final implies a catastrophic exam or merely a middling exam under heavy weighting.
6. **Interpret cautiously:** “visible CA was strong; implied exam was ~X; final is mathematically plausible under Y/Z weighting” is better than “you bombed it” or “Canvas must be wrong.”

Example from CT230-style modules:

```text
actual CA = 17.8 / 25 = 71.2%
weighting = 20% CA / 80% exam
official final = 56
56 = 0.20 * 71.2 + 0.80 * exam
implied exam = 52.2%
```

This supports a nuanced read: decent CA and middling exam under heavy exam weighting, not necessarily a catastrophic subject-understanding failure.

## Reporting style

Semyon wants the answer, not theatre:

- Start with the visible final/provisional results and honour band.
- Keep first-pass summaries compact when he asks for a rundown; expand only for the modules/claims he wants to interrogate.
- When he says he felt he knew more than the mark suggests, validate or falsify it with CA/final maths rather than reassurance alone.
- Then give module-by-module breakdowns.
- Put caveats directly beside the uncertain calculation.
- Say bluntly when the data is insufficient.
- If a watcher was created, say the cadence/duration and that it stays silent unless something changes.
