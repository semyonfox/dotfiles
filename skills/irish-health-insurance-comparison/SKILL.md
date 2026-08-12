---
name: irish-health-insurance-comparison
description: "Use when compare Irish private health-insurance plans for genuine cover/value using HIA plan data, without creating insurer sales leads or using invented identities."
version: 1.0.0

metadata:
  harness: [hermes]
---

# Irish health-insurance comparison

## When to use

Use for plan renewals, family cover reviews, insurer switches, or “same/better cover for less” research in Ireland.

## Core rule: HIA first, quote forms last

Start with the statutory **Health Insurance Authority (HIA)** comparison tool and plan data. It covers regulated Irish plans and is appropriate for anonymous plan research.

Do **not** submit invented names, emails, phone numbers, addresses, or medical details to commercial quote forms. If an exact insurer quote genuinely requires personal details, ask the user to enter them themselves or obtain their explicit confirmation to use authentic details.

## Workflow

1. **Build the baseline.** Extract each member’s plan, category (adult / young adult / child), and annual premium; calculate the annual household total with a tool.
2. **Separate the household by need.** A family does not need one shared plan. Keep children/young adults separate from adults where their requirements and age pricing differ.
3. **Define non-negotiables before ranking:**
   - hospital network: public/private, semi-private/private room, and locally relevant hospitals;
   - inpatient excess: per claim, per night, limits/caps;
   - Beacon, Blackrock Clinic, Mater Private and relevant local private hospitals;
   - orthopaedic, cardiac, and ophthalmic co-payments/shortfalls;
   - specific outpatient requirements such as physio, podiatry/chiropody, GP, mental health, maternity/fertility.
4. **Use HIA plan data** to retrieve actual active-plan benefits and category prices. Inspect benefit items, not marketing names.
5. **Produce two rankings where useful:**
   - **direct replacement** — closest hospital-cover match with savings;
   - **needs-led option** — best specified outpatient support, explicitly calling out any network/cover trade-off.
6. **Verify finalists** at the insurer’s official plan/hospital documentation and check HIA notices for imminent price/benefit changes before a purchase recommendation.

## HIA public-data endpoints

The HIA frontend uses `https://api.hia.ie/api/v1`.

- `GET /insurers`
- `GET /insurers/plans/{insurerId}`
- `GET /plans/search/{term}`
- `GET /plans/planIdsToVersionIds/{id1|id2}/YYYY-M-D`
- `POST /plans/compare` with `{"versionIds":[...],"date":"YYYY-MM-DD"}`

The compare response contains plan benefit groups, inpatient excess, and prices by adult/young-adult/child category. Use it to inspect active plans at scale. See [HIA data and benefit comparison notes](references/hia-data-and-benefit-comparison.md).

## Decision rules and pitfalls

- Do not call a cheaper plan “the same cover” if it pays only at a semi-private rate, adds a per-night shortfall, raises an excess, excludes a relevant hospital, or limits a relevant procedure.
- **“Same or better” is an all-material-benefits test.** A plan may be best for the stated needs but still have a trade-off (e.g. psychiatric days); state it plainly.
- For foot/physio needs, distinguish standalone physiotherapy cover, podiatry/chiropody cover, and combined practitioner pots: a plan advertising both may have only one shared allowance.
- A low plan price frequently conceals a high excess, shortfall, hospital exclusion, or procedure co-payment. Treat those as costs, not footnotes.
- If prices/benefits change within days, date-stamp figures and re-check finalists at the effective date.

## Output shape

Give a short recommendation first: plan name, per-person price, household saving, why it fits, and the one material caveat. Follow with a compact comparison table and final verification steps. Avoid a generic plan dump.
