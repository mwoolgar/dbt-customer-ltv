-- Grain: one row per order that contains at least one valid item. Second fact table of the star.
with lines as (
    select * from {{ ref('fct_order_lines') }} where is_valid_sale
),
orders as (
    select
        order_id,
        any_value(customer_key)     as customer_key,
        any_value(channel_key)      as channel_key,
        min(order_date)             as order_date,
        count(*)                    as items,
        sum(net_revenue)            as net_revenue,
        sum(net_margin)             as net_margin
    from lines
    group by order_id
)

select
    order_id,
    customer_key,
    channel_key,
    cast(format_date('%Y%m%d', order_date) as int64)    as order_date_key,
    order_date,
    items,
    net_revenue,
    net_margin,
    row_number() over w                                 as order_sequence,
    row_number() over w = 1                             as is_first_order,
    date_diff(order_date, lag(order_date) over w, day)  as days_since_previous_order
from orders
window w as (partition by customer_key order by order_date, order_id)
