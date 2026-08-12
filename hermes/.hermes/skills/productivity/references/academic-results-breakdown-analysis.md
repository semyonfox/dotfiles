# Academic results breakdown analysis

Use this when Semyon asks to reconcile official university results with Canvas/LMS CA, provisional marks, exam weights, or his subjective sense of how a paper went.

## Core principle

Separate three things clearly:

1. **Official result** — portal/transcript result, final/provisional module mark.
2. **Visible LMS evidence** — Canvas assignments, assignment groups, provisional marks, announcements, module overview PDFs, exam-info files.
3. **Inferred components** — reverse-engineered exam marks or hidden component estimates. Label these as inferred.

Do not collapse “low official mark” into “low competence”. Semyon often has strong practical/project evidence and strong CA, while exams can reflect rubric alignment, formal notation, brittle lab compile/run marking, or hidden components.

## Workflow

1. **Pull official marks first**
   - Use the official results portal data if already captured.
   - Avoid repeating student ID, password, cookies, or other secret material.

2. **Pull Canvas/LMS evidence**
   - Courses/enrollments for active/completed terms.
   - Assignments with submissions.
   - Assignment groups and group weights.
   - Announcements containing: `grade`, `mark`, `overall`, `provisional`, `exam`, `CA`, `continuous`, `assessment`, `weight`, `result`.
   - Relevant files/module PDFs such as module overview, summary, exam info, sample solutions.

3. **Confirm weights from source documents**
   - Do not assume 70/30. Some modules are 80/20, 60/40, 100% CA, or have hidden components.
   - Prefer module overview/exam-info PDFs or explicit Canvas assignment group weights over guesswork.

4. **Calculate inferred exam marks**

```text
exam = (final - ca_weight * ca_mark) / exam_weight
```

Show the equation for modules where it matters. Keep a distinction between official/provisional values and inferred values.

5. **Interpret mismatches by assessment mode**

Common patterns from Semyon’s results:

- Strong CA/practical work + lower exam final can indicate exam-conversion leakage, not lack of knowledge.
- Production-grade answers can be poor exam answers if they diverge from the rubric. For example, PostgreSQL-specific UUID/migration/version-check designs may not score well where the expected answer is a simple taught `INT PRIMARY KEY` schema.
- Large lab-programming exams in constrained IDEs can be brittle: a single syntax typo or dependency-loop compile failure may lose compile/run marks even with good design intent.
- Formal maths/stats papers can expose genuine weak spots separate from practical CS competence.

6. **Identify what is worth querying**

Prioritize consultation/recheck requests when:

- Visible CA is high but final is unexpectedly low.
- The student completed the exam comfortably and the implied exam mark seems inconsistent.
- There may be rubric mismatch, over-engineering, or non-compilation penalties.
- Canvas shows a provisional mark but not a question-by-question breakdown.

Lower priority when:

- Canvas explicitly shows CA/exam/final and the exam mark explains the result.
- The user agrees the paper was time-pressured or went badly.

## Consultation/recheck guidance

University-style rechecks often only recalculate marks; they do not re-mark content. A consultation with the lecturer/school is usually the right first step.

Ask for:

- CA total used.
- Exam mark.
- Question-by-question breakdown where available.
- Confirmation of weighting/calculation.
- How optional questions were handled if more than required were attempted.
- Whether non-compiling code received partial credit and how compile/run/design marks were split.
- Whether README notes or examiner notes were considered.

### Template: module breakdown request

```text
Hi [Lecturer],

I hope you are well. I received my provisional result for [MODULE] and would appreciate a breakdown if possible.

My final mark is showing as [MARK]%. Based on Canvas I can see [CA EVIDENCE], and I would like to understand how the final mark was calculated, particularly the CA total used and the exam/lab mark breakdown if available.

Could I please arrange a time to discuss this, or could you point me to the correct process for reviewing the module breakdown?

Kind regards,
Semyon Fox
```

### Template: programming lab compile-failure breakdown

```text
Hi [Lecturer],

I’m trying to understand my [MODULE] final mark and would appreciate a breakdown if possible.

My coursework marks were strong, but in the lab exam I had a compile failure caused by a typo/dependency issue and noted this in the examiner README. I’d like to understand how much of the lab exam mark was lost due to non-compilation versus design/implementation/content issues.

Could I please see the breakdown for the lab exam, including compile/run marks, design/OOP marks, and any partial credit awarded?

Kind regards,
Semyon Fox
```

## Reporting style

Semyon wants direct, compact diagnosis first, then detail:

- Start with “what the data says”.
- Then list confirmed facts vs inferred estimates.
- Validate genuine mismatch without turning it into empty reassurance.
- Avoid saying “you don’t know X” when evidence suggests assessment mismatch.
- Use blunt labels: `not suspicious`, `worth querying`, `genuine weak spot`, `rubric mismatch likely`.
