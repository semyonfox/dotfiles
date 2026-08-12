# University of Galway module-selection research

Use this as a concrete source pattern when Semyon is choosing University of Galway modules, particularly GY350 third-year options.

## Authoritative module records

The legacy-looking module endpoint is current and exposes a short description, learning outcomes, assessment weightings, teachers, validity year, and credits:

`https://www.universityofgalway.ie/course-information/module/<MODULE_CODE>`

The accessible view can omit list text, but the rendered page source/DOM contains it. Inspect the `Learning Outcomes` and `Assessments` HTML when the accessibility tree shows blank list items.

The programme curriculum page lists the currently offered options:

`https://www.universityofgalway.ie/courses/undergraduate-courses/computer-science-and-information-technology.html`

Expand **Curriculum**, then inspect the Year 3 accordion. Treat course/module offerings as subject to change.

## GY350 Year 3 options checked in July 2026

All were listed as 5 ECTS, Semester 5.

| Module | Official scope | Assessment shown | Practical decision read |
|---|---|---:|---|
| CT318 Human Computer Interaction | Conceptual design models, alternative and interactive prototypes, evaluation of prototypes and real systems | Written 70%, CA 30% | Strong low-risk fit for Semyon's product, UX, and accessibility work. |
| CT331 Programming Paradigms | Generic C functions/function pointers; Lisp functional programs; Prolog/list processing; tail recursion; comparing procedural, functional, and logical paradigms | Written 85%, CA 15% | Strong CS foundation, but a concentrated exam risk in an already compressed semester. |
| CT3536 Games Programming | Modern game engine; interactive media; game-engine architecture; physics; graphics, materials, lights, cameras; performance-aware reusable code | Written 70%, CA 30% | Good fit for Semyon's programming/projects; avoid scope creep in the CA game build. |

## Recommendation frame

Do **not** call a module globally “easy” without grade-distribution or recent-assessment evidence. Instead compare:

1. assessment concentration (especially high final-exam weight),
2. overlap with Semyon's existing proven work,
3. novelty and prerequisite gap,
4. probability of uncontrolled project scope,
5. direct placement/portfolio value.

For a grade-protection strategy, CT318 is the safest default. CT3536 is a sensible companion when Semyon wants a portfolio-friendly technical option and commits to a deliberately small, complete game. CT331 is the alternative when he values theory/CS breadth and is willing to pre-study Lisp, Prolog and recursion.
