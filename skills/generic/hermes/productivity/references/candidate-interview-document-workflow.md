# Candidate interview document workflow

Use when Semyon forwards recruiter emails, NDAs, job descriptions, candidate brochures, calendar invites, or interview logistics.

## Workflow

1. Extract the actual documents first; do not ask Semyon to paste contents.
   - PDFs: use `pdftotext -layout` or another layout-preserving extractor, then render each page to PNG and inspect visual hierarchy, whitespace, clipping, and accidental page breaks.
   - DOCX/PPTX: unzip and read Office XML text when library support is missing; inspect slides/relationships for embedded images that carry important information such as maps.
   - Raw email `.txt`/`.eml`: parse MIME parts before assuming attachments exist. A large base64 block may be `text/calendar`, not a PowerPoint/PDF.
2. For CV tailoring, select the strongest existing technical CV as the base rather than using auto-generated LinkedIn exports. LinkedIn-generated PDFs with profile labels, generic summaries, or no projects/skills are not application-ready.
   - For a student SDE application, prefer a readable **one-page** CV where possible: education and CS fundamentals; concise technical skills; 3--4 strongest technical projects; then leadership/work evidence.
   - Map the job requirements to interview-defensible evidence. For Amazon-style SDE roles, foreground data structures/algorithms, OOP, SQL/relational databases, APIs, async/background work, service boundaries, reliability/monitoring, testing, and one concrete project that spans web/API, database, queue/worker, or storage layers. Do not claim professional distributed-systems or optimisation experience that the candidate cannot discuss.
   - Remove employer-specific language from a prior targeted CV before reusing it. Verify dates, role titles, availability, degree completion date, links, and claims against the source of truth.
   - Compile the final PDF, check that it is one page when intended, re-extract text for ATS readability, and visually inspect the rendered output. If a system TeX install is unavailable, a user-local Tectonic binary is a practical non-root compiler: download the signed/released Linux archive from the upstream GitHub release, run `tectonic -X compile --outdir <build-dir> <file.tex>`, then retain the generated PDF and source without overwriting the generic base.
3. Separate categories clearly:
   - legal/contract meaning, with a non-lawyer caveat;
   - role/team signal;
   - interview logistics;
   - prep strategy;
   - reply drafting.
3. For NDAs, summarize practical obligations and red flags:
   - confidentiality scope;
   - permitted use/purpose;
   - exceptions/public information;
   - return/deletion of materials;
   - no job guarantee;
   - non-compete/IP assignment/arbitration/liability red flags if present.
4. For recruiter replies, keep the tone human and non-AI-ish. Semyon prefers concise, natural wording over polished corporate filler.
   - Good: “It’s great to hear I’ve been shortlisted for an interview.”
   - Avoid overstuffed lines like “I’m delighted to confirm my enthusiastic interest…”
   - Mention attachments/JD only lightly if useful.
5. For interview-slot strategy, weigh the candidate’s actual energy/routine over generic first/last-candidate folklore. For Semyon, morning can be good if he can do a controlled swim/dip, coffee, and brief social warm-up.
6. For business-casual/interview clothing advice, be concrete: shirt + chinos/smart trousers + clean shoes; tie/jumper can be acceptable if softened and not court-formal.

## Online internship applications

When helping Semyon complete a recruiter-linked application, verify the job against its official employer URL/job ID first, then answer the actual form rather than paraphrasing the recruiter message.

- Give only truthful availability. Do not stretch an internship-duration or start-date answer to look more flexible; an offer and project plan will rely on it.
- Treat “adjustments” as recruitment/interview accommodations (for example, captions, screen-reader support, breaks, or extra assessment time), **not** normal relocation or travel time.
- For compliance questions, distinguish student status from employment. A student is not automatically an employee of a publicly funded university. However, a paid/direct role with an Irish Education and Training Board or public school is government/public-sector employment for a form that explicitly includes public institutions; select current/former status according to the dates. Unpaid volunteering or third-party contracting needs separate confirmation.
- For work-authorisation questions, an Irish citizen applying in Germany normally does not require employer immigration sponsorship. Do not infer citizenship or prior Amazon/affiliate applications: ask or state the conditional choice when unknown.
- A generic EMEA template may ask for “top three” location preferences while exposing a single-select field. Use the available control faithfully; do not invent rankings or try to force extra locations into it.
- For a company-specific CV, never upload a PDF that names another employer in its availability line or target-role summary. If a tailored source file is not yet rendered/verified, use the strongest clean generic PDF rather than an unverified or wrongly branded variant.

## Technical CV tailoring and PDF handoff

When Semyon is actively completing a technical internship application, inspect the actual PDF(s) and source files before advising. Do not approve a LinkedIn auto-generated resume merely because it has correct facts: reject exports with profile-field labels, auto-generated notices, missing projects/skills, or broken pagination.

1. Compare the generic CV against any role-specific version. Prefer a **one-page, project-led base** for an early-career SDE application, but never reuse a version whose header names another employer.
2. Make a new role-specific source/PDF rather than silently overwriting the generic CV. Retain only truthful keywords supported by concrete projects: for SDE work this often means DSA/OOP modules, API/database/queue/worker boundaries, async jobs, testing, cloud, Linux, deployment, and operational ownership.
3. Prioritise 2--3 strongest projects and one concise leadership entry over an exhaustive project inventory or awards list. Explain multi-tier/distributed work accurately: distinguish a junior project with separate web/API, database, worker, queue, and storage services from claimed hyperscale experience.
4. Keep technical interests out of the Interests section when they already dominate the CV. One short, human line of non-redundant interests (for Semyon: competitive swimming, DaVinci editing/colour grading, woodworking) can add personality without wasting technical space.
5. Treat visual density as a real quality gate. A technically comprehensive one-pager that looks cramped is worse than a cleaner selective version. Increase readability through measured font/line/section spacing and selective cuts, not arbitrary blank space. Check actual rendered pages for clipping, page count, hierarchy, and whether the bottom section feels intentional.
6. Verify the final PDF is one page when that is the target, has no layout warnings, and is text-extractable for ATS. Preserve a clearly named final upload artifact (for example `SEMYON_FOX_CV.pdf`) only after that check.

A user-local Tectonic compile is a useful no-system-install fallback when TeX tooling is unavailable: compile to a temporary output directory, inspect warnings, extract PDF text, and render a page image for visual QA. Do not claim a generated `.tex` file is ready until it has compiled and been checked.

## Output shape

- Start with the decision/verdict first.
- Then give the practical meaning/actions.
- Keep legal/contract analysis clear but not panic-inducing.
- For emails, provide one final sendable draft, not five variants unless asked.

## Pitfalls

- Do not claim an attachment was decoded unless MIME parsing or file extraction confirms it.
- Do not treat recruiter brochures as technical gospel; they are usually culture/logistics material.
- Do not let email drafts sound like generic AI career-coach prose; Semyon actively trims that tone.
