-- Grain: lifecycle stage x customer type x acquisition channel
select
    l.lifecycle_stage,
    l.customer_type,
    ch.channel_name,
    count(*)                                as customers,
    sum(l.net_revenue)                      as net_revenue,
    sum(l.net_margin)                       as net_margin,
    avg(l.orders)                           as avg_orders,
    avg(l.days_since_last_order)            as avg_days_since_last_order
from {{ ref('fct_customer_lifecycle') }} l
join {{ ref('dim_channel') }} ch using (channel_key)
group by 1, 2, 3
