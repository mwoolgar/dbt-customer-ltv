-- Grain: acquisition month x channel, mature cohorts only. Mirrors the "Data Entry" tabs of the workbook.
with customers as (
    select * from {{ ref('fct_customer_ltv') }} where is_mature_cohort
)

select
    c.cohort_month,
    ch.channel_name,
    count(*)                                                        as customers,
    sum(c.first_order_revenue)                                      as first_order_revenue,
    sum(c.first_order_margin)                                       as first_order_margin,
    sum(c.repeat_revenue)                                           as repeat_revenue,
    sum(c.repeat_margin)                                            as repeat_margin,
    sum(c.total_orders)                                             as total_orders,
    countif(c.has_repeat_purchase)                                  as repeat_customers,
    safe_divide(sum(c.first_order_revenue + c.repeat_revenue), count(*))   as ltv_revenue,
    safe_divide(sum(c.first_order_margin + c.repeat_margin), count(*))     as ltv_margin,
    safe_divide(sum(c.first_order_revenue), count(*))               as first_aov,
    safe_divide(countif(c.has_repeat_purchase), count(*))           as repeat_rate,
    safe_divide(sum(c.repeat_revenue), countif(c.has_repeat_purchase)) as repeat_value_per_repeater,
    safe_divide(sum(c.total_orders), count(*))                      as orders_per_customer
from customers c
join {{ ref('dim_channel') }} ch using (channel_key)
group by 1, 2
