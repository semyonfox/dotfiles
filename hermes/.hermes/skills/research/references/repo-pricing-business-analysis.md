# Repo-Based Pricing and Salary-Replacement Analysis

Use when the user asks whether a product in a local repo can match a salary, support a founder, or reach a revenue target.

## Workflow

1. Locate the product repo before estimating. Search by product name and inspect README/docs for pricing, cost, and unit-economics files.
2. Treat repo docs as the source of truth over memory. In OghmaNotes-like repos, check both the general pricing plan and any feature-specific cost reports because the margin risk may live in one subsystem.
3. Separate at least three targets:
   - gross revenue match: target annual income / 12 / plan price
   - contribution/profit-ish match: target monthly income / estimated net contribution per user
   - payroll-safe match: include employer taxes/PRSI or company overhead where relevant
4. For freemium products, make clear that free users only matter through conversion and support/infra load; they do not directly replace salary.
5. Run arithmetic with a tool, not mental math. Round user counts up.
6. Call out the limiting economic risk, not just the headline subscriber count. For study apps with imports/OCR/RAG, first-import backlogs and expensive managed APIs can dominate normal monthly usage.

## Output Shape

Keep the answer compact and decision-useful:

- salary or annual target converted to monthly target
- user counts for each paid tier and a few blended-plan scenarios
- distinction between gross MRR and net contribution
- one blunt read on whether the target is plausible and what could break the model

## OghmaNotes Pattern Captured

For OghmaNotes-style analysis, the docs showed a free acquisition tier, a EUR 10/month Standard launch tier, and future higher tiers. The Standard model estimated roughly EUR 8.50/month net contribution after Stripe and normal AI/OCR/storage costs. Canvas import economics were the major margin hazard: normal recurring usage could fit under limits if processed via text extraction/GPU batching, while managed document APIs were not viable for steady-state imports.
