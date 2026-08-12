# HIA data and benefit comparison notes

## Useful API pattern

```text
GET  https://api.hia.ie/api/v1/insurers/plans/{insurerId}
GET  https://api.hia.ie/api/v1/plans/search/{term}
GET  https://api.hia.ie/api/v1/plans/planIdsToVersionIds/{id1|id2}/YYYY-M-D
POST https://api.hia.ie/api/v1/plans/compare
     {"versionIds":[...],"date":"YYYY-MM-DD"}
```

`/plans/compare` returns a plan object with:
- `active`, `visible`, `basic`, `insurer`, `inpatientExcess`;
- `prices`, with Adult, Young Adult, and child category/range prices;
- `groups` containing named hospital and outpatient benefit items.

## Minimum benefit fields to compare

### Hospital cover
- `Private hospital - semi-private room - overnight`
- `Private hospital - private room - overnight`
- `Hi tech hospital - standard procedures - overnight`
- `Hi tech hospital - day case`

Read both `value` and `variable`: the latter often contains the real excess, hospital exclusions, nightly shortfall, and procedure co-payment.

### Outpatient needs
- `Physiotherapist`
- `Chiropodist / Podiatrist`
- `Alternative therapies and other practitioners`
- `GP Visits`
- `Consultant Fees`

A direct `Physiotherapist` benefit can coexist with a separate combined practitioner allowance. Do not add them unless terms permit it.

## Example comparison logic

For each candidate, extract the adult price, excess and above benefit strings. Remove candidates where:
- private-hospital payment is only a semi-private rate when full private cover is required;
- excess exceeds the user's maximum;
- a required hospital is excluded;
- an outpatient benefit is marked not covered or the allowance is too small.

Then rank by annual price and show savings relative to the current plan. Preserve a second list of needs-led alternatives that deliberately relax a hospital requirement, clearly labelled as a trade-off.

## Caveat

Prices and benefits are point-in-time data. HIA notices may list pending insurer changes. Re-run the active-version/date check on or after the effective date before any purchase.