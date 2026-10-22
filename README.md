# ltv_thelook

dbt Core (BigQuery) project that builds a star schema, 12-month customer LTV models, and retention / churn /
lifecycle models from the public `bigquery-public-data.thelook_ecommerce` dataset.

## Layers
| Layer | Models |
|---|---|
| staging (views) | `stg_thelook__order_items`, `stg_thelook__orders`, `stg_thelook__users`, `stg_thelook__products`, `stg_thelook__events` |
| star schema (tables) | facts `fct_order_lines`, `fct_orders`; dimensions `dim_customer`, `dim_product`, `dim_channel`, `dim_date` |
| LTV marts | `fct_customer_ltv`, `fct_cohort_ltv`, `rpt_channel_ltv`, `rpt_ltv_curve`, `fct_first_order_profile`, `rpt_category_repeat`, `rpt_returns_repeat`, `rpt_category_returns` |
| retention marts | `fct_customer_lifecycle`, `fct_cohort_retention`, `rpt_reactivation_by_inactivity`, `rpt_lifecycle_summary`, `rpt_funnel` |

## Run
```
pip install dbt-bigquery
copy profiles.yml.example profiles.yml          # Windows; project is local-volt-dbt
gcloud auth application-default login
dbt build --profiles-dir .
```
The public dataset is in the US multi-region, so the dataset dbt writes to must be in `US` (set in the profile).

## Variables (dbt_project.yml)
| Var | Default | Meaning |
|---|---|---|
| `ltv_window_months` | 12 | LTV window |
| `valid_statuses` | Complete, Shipped, Processing | items that count as a sale |
| `date_spine_start` | 2019-01-01 | start of `dim_date` |
| `active_days` | 90 | Active: ordered within this many days |
| `cooling_days` | 180 | Cooling: up to this many days |
| `churn_days` | 365 | At risk up to here; beyond it a customer is Lapsed / churned |

Override with `--vars '{churn_days: 545}'`.

## Definitions
- Order date: `orders.created_at`. Items on one order can carry different item dates (about 26% of orders), so the order, not the item date, decides first versus repeat.
- Orders and items dated in the future are dropped in staging (the dataset contains rows up to a few days ahead).
- Valid sale: item status Complete, Shipped or Processing.
- First order: the customer's first order (by `order_id`). Repeat: valid lines from any other order within the window.
- LTV = (first + repeat) / customers. Margin = sale price minus product cost.
- Mature cohort: acquisition month at least `ltv_window_months` before the latest order month.
- Churn is inactivity, since the data has no subscriptions. Lifecycle stage by days since last order: Active, Cooling, At risk, Lapsed. Lapsed is churned. 365 days was chosen because the 90-day return chance falls to about 4% by then, but the curve has no sharp elbow, so test other cutoffs with `churn_days`.
- Events exist only for customers who ordered, and `session_source` differs from `users.traffic_source`, so `rpt_funnel` overstates real-site conversion.
- Data is synthetic and refreshed daily, so figures change slightly between runs.
