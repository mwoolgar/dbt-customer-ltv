# Aggregation rules: never average a rate column

Several certified marts store a **rate or average already computed per row** (per channel, per
category, per cohort, per stage). Taking a plain `AVG()` of that column across several rows is
almost always wrong — it treats a small row and a large row as equally important, and silently
ignores volume. This is "averaging an average." Apply this guide before an agent or a person writes
`AVG(some_rate_column)` against any certified mart.

## The rule
For any ratio column, re-derive it from its underlying numerator and denominator columns
(both present in the same table), summed across the rows you're grouping — then divide once:

```
-- Wrong: averaging an already-averaged column
SELECT AVG(repeat_rate) FROM rpt_channel_ltv;

-- Right: re-aggregate the numerator and denominator, then divide
SELECT SAFE_DIVIDE(SUM(repeat_customers), SUM(customers)) FROM rpt_channel_ltv;
```

If the table only stores the ratio and not its parts, go to the row-level mart it was built from
(check the model's `ref()`) instead of averaging the ratio.

## Every stored ratio/average column, and how to recombine it

| Mart | Ratio column | Correct re-aggregation | Weight (what each row represents) |
|---|---|---|---|
| `rpt_channel_ltv` | `repeat_rate` | `SUM(repeat_customers) / SUM(customers)` | customers per channel |
| `rpt_channel_ltv` | `first_aov`, `ltv_revenue`, `ltv_margin` | `SUM(revenue cols) / SUM(customers)` | customers per channel |
| `rpt_channel_ltv` | `orders_per_customer` | `SUM(total_orders) / SUM(customers)` | customers per channel |
| `rpt_category_repeat` | `repeat_rate`, `ltv_revenue`, `ltv_margin`, `first_aov` | same pattern — go back to `fct_first_order_profile` and re-divide by `COUNT(*)` of customers in the categories you're grouping | customers per category |
| `rpt_returns_repeat` | `repeat_rate`, `ltv_revenue`, `ltv_margin` | only 2 rows, split by `first_order_returned` (ORDER-level, not item-level — see model header comment) — don't average them together, that erases the comparison the table exists to show | n/a — compare, don't collapse |
| `rpt_category_returns` | `return_rate` | `SUM(returned items) / SUM(returned + valid items)`, recomputed from `fct_order_lines` | items per category |
| `fct_cohort_retention` | `retention_rate` | `SUM(active_customers) / SUM(cohort_customers)` | `cohort_customers` per cohort×channel×month row |
| `rpt_lifecycle_summary` | `avg_orders`, `avg_days_since_last_order` | weighted by `customers`: `SUM(avg_orders * customers) / SUM(customers)` | customers per stage×channel |
| `rpt_funnel` | `cart_rate`, `cart_to_purchase_rate`, `cancel_rate` | `cart_rate`: `SUM(cart sessions)/SUM(sessions)`; `cart_to_purchase_rate`: `SUM(purchase sessions)/SUM(cart sessions)` — the two rates don't share a denominator, so never average them together either | sessions per source |
| `rpt_reactivation_by_inactivity` | `return_rate_90_days`, `eventual_return_rate` | weighted by `days_observed` / `at_risk_orders` per bucket | orders observed per inactivity bucket |

## The two columns that are safe to average directly
- `fct_customer_lifecycle.avg_order_value` and `avg_days_between_orders` are genuine per-customer
  figures (one customer, several of their own orders). Averaging these **across customers** still
  needs the same care — weight by each customer's own order count if you want an order-weighted
  figure, or accept a customer-weighted figure if that's what the question actually asks (usually
  the right default: "the average customer's average order value").
- Anything built through the **semantic layer** (`models/semantic/`) is already safe: `ltv_revenue`,
  `repeat_rate`, `churn_rate`, `active_customer_rate`, `ltv_margin`, `first_order_aov` are all typed
  as `ratio` metrics over row-level semantic models, so MetricFlow sums the numerator and denominator
  measures separately before dividing, at whatever grain you ask for. Prefer these over a `rpt_*`
  table's stored column when the question involves grouping or re-slicing.

## Why this matters for the interview
This is the concrete version of "Simpson's paradox" / mix-shift risk that the `analytics-diagnostic-method`
approach warns about: a rate that looks flat or improving in aggregate can hide a mix shift between
large and small segments. Stating the rule explicitly, and showing the numerator/denominator pair for
any rate you report, is a defensible habit to describe if asked how you'd prevent a misleading number.
