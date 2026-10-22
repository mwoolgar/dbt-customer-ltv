-- Grain: category of the highest-value item on the customer's first order (mature cohorts only)
select
    top_category,
    count(*)                                                            as customers,
    safe_divide(countif(has_repeat_purchase), count(*))                 as repeat_rate,
    safe_divide(sum(first_order_revenue + repeat_revenue), count(*))    as ltv_revenue,
    safe_divide(sum(total_margin), count(*))                            as ltv_margin,
    safe_divide(sum(first_order_revenue), count(*))                     as first_aov
from {{ ref('fct_first_order_profile') }}
group by 1
