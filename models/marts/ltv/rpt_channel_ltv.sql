-- Grain: one row per channel, all mature cohorts combined
select
    channel_name,
    sum(customers)                                                          as customers,
    safe_divide(sum(first_order_revenue), sum(customers))                   as first_aov,
    safe_divide(sum(repeat_customers), sum(customers))                      as repeat_rate,
    safe_divide(sum(total_orders), sum(customers))                          as orders_per_customer,
    safe_divide(sum(first_order_revenue + repeat_revenue), sum(customers))  as ltv_revenue,
    safe_divide(sum(first_order_margin + repeat_margin), sum(customers))    as ltv_margin
from {{ ref('fct_cohort_ltv') }}
group by 1
