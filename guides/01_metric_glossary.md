# Metric glossary

Certified metrics live in `models/semantic/_semantic_models.yml` (MetricFlow semantic layer). This
table is the same definitions in plain language, for a reader or agent who won't parse YAML.

| Metric | Definition | Source mart | Caveat |
|---|---|---|---|
| `ltv_revenue` | Revenue per mature-cohort customer across the first order + 12 months of repeats | `fct_customer_ltv` | Mature cohorts only |
| `ltv_margin` | Same, using margin (sale price − product cost) | `fct_customer_ltv` | |
| `repeat_rate` | Share of mature-cohort customers who ordered again within 12 months | `fct_customer_ltv` | ~16%, not 38% — see known pitfalls |
| `first_order_aov` | Average revenue of a customer's first order | `fct_customer_ltv` | |
| `churn_rate` | Share of customers with no order for more than `churn_days` (365) | `fct_customer_lifecycle` | Always state the cutoff |
| `active_customer_rate` | Share of customers who ordered within `active_days` (90) | `fct_customer_lifecycle` | |
| Lifecycle stage | Active (≤90d) / Cooling (91–180d) / At risk (181–365d) / Lapsed (>365d) since last order | `fct_customer_lifecycle` | Days are `var`s, override with `--vars` |
| RFM segment | Champions / Loyal / Developing / Slipping repeaters / Recent one-timers / Lapsed one-timers, from recency/frequency/monetary quintiles | `fct_customer_lifecycle` | Quintiles are relative to this dataset, not an industry scale |
| Retention rate (month N) | Share of an acquisition cohort that placed an order in calendar month N after acquisition | `fct_cohort_retention` | Month 0 is 100% by definition |
| Return rate (N days) | Chance of ordering again within 90 days, given N days of prior silence | `rpt_reactivation_by_inactivity` | Basis for the churn cutoff — curve has no sharp elbow |

## Variables that change these numbers
Set in `dbt_project.yml`, overridable with `dbt build --vars '{...}'`:
`valid_statuses`, `ltv_window_months` (12), `active_days` (90), `cooling_days` (180), `churn_days` (365).

Any answer quoting churn rate, lifecycle stage counts, or retention should name the variable values
used, since they are judgement calls baked into the model, not fixed facts about the data.
