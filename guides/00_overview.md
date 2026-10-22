# Guide: this project, in plain language

Read this before answering any question with `local-volt-dbt.ltv_marts`. It's the equivalent of a
Hex workspace guide or a system prompt for an agent working over this data.

## What this is
A customer LTV, retention and churn analysis built with dbt on the public BigQuery dataset
`bigquery-public-data.thelook_ecommerce` — a synthetic fashion e-commerce store. **The data is not
real.** It demonstrates method, not real shopper behaviour, so never present a number from here as
a real business result.

## Where to query
Only the tables tagged `meta.certified: true` in `dbt_project.yml` — everything under
`models/marts/ltv/` and `models/marts/retention/`. Do not query `models/marts/core/` (the star
schema) or `models/staging/` directly; they exist to build the certified marts, not to be reported
from. If a question needs a join those marts don't already provide, say so rather than writing new
SQL against the star schema.

## Rules the data itself can't tell you
- **Churn is a judgement call, not a fact.** It's defined as inactivity (no order for more than
  `churn_days`, default 365), because this store has no subscriptions. The 90-day return-chance curve
  (`rpt_reactivation_by_inactivity`) has no sharp elbow, so always state the cutoff next to any churn
  number, and never call a customer "lost" — about a third of year-long-silent customers return.
- **"Repeat" is decided by order, not by item.** An order's items can carry different timestamps
  (~26% of orders); the split always uses `order_id`, never `item_created_date`. A model that
  mentions item-level dates for this purpose is wrong — this project shipped that bug once already
  (see `/guides/02_known_pitfalls.md`).
- **LTV = revenue over the first order plus 12 months of repeats**, per customer in a *mature*
  cohort (one whose 12-month window has already closed). Immature cohorts are excluded from every
  LTV and repeat-rate figure — don't average them in.
- **`rpt_funnel` overstates conversion.** Events only exist for customers who went on to order, so
  cart and purchase rates read higher than a real site would show.
- **Channel and category barely move repeat rate.** They mostly explain LTV through basket size
  (AOV), not through loyalty. Don't manufacture a channel story the data doesn't support.

## When to say "I don't know" instead of answering
- A question needs cost or marketing-spend data — there is none in this dataset, so CAC, ROI and
  payback can't be answered from it (the dashboard's payback calculator takes cost as a *user input*,
  not a known figure).
- A question is about real customers, real revenue, or compares this store to the business you
  actually work in — this is a portfolio project on public synthetic data.
- A question needs a time grain or segment not already in a certified mart — check `/guides/01_metric_glossary.md` and the semantic layer (`models/semantic/`) before writing new SQL.

## Never average a rate column
Several certified marts (`rpt_channel_ltv`, `fct_cohort_retention`, `rpt_funnel`, and others) store a
ratio already computed per row — `repeat_rate`, `retention_rate`, `cart_rate`. Taking `AVG()` of one
of those across rows is averaging an average: it ignores how many customers/sessions each row
represents. Always re-sum the numerator and denominator columns and divide once, or use the matching
metric in `models/semantic/`. Full table of every affected column: `03_aggregation_rules.md`.

## Two different "repeat rate" numbers exist — name which one you mean
`fct_customer_ltv` gives a 12-month repeat rate on mature cohorts only (16.4%);
`fct_customer_lifecycle.customer_type` gives an all-time repeat share on every customer (~31%). Both
are correct for what they measure. Never quote one without saying which. Full explanation:
`04_metric_scope_notes.md`.

See also: `01_metric_glossary.md` (every metric name and its definition), `02_known_pitfalls.md`
(mistakes already made and fixed, worth re-checking before trusting a new number),
`03_aggregation_rules.md` (which stored columns are ratios, and how to recombine them correctly),
`04_metric_scope_notes.md` (why two correct "repeat rate" numbers can disagree).
