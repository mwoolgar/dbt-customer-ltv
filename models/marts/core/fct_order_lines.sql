-- Grain: one row per order item (all statuses). Use is_valid_sale to restrict to real sales.
-- order_date is the date the ORDER was placed (orders.created_at), not the item timestamp,
-- because items on one order can carry different dates (about a quarter of orders).
with items as (
    select * from {{ ref('stg_thelook__order_items') }}
),
orders as (
    select order_id, order_date from {{ ref('stg_thelook__orders') }}
),
users as (
    select customer_id, traffic_source from {{ ref('stg_thelook__users') }}
),
products as (
    select product_id, cost from {{ ref('stg_thelook__products') }}
)

select
    i.order_item_id                                             as order_line_key,
    i.order_id,
    i.customer_id                                               as customer_key,
    i.product_id                                                as product_key,
    {{ channel_key('u.traffic_source') }}                       as channel_key,
    cast(format_date('%Y%m%d', coalesce(o.order_date, i.item_created_date)) as int64) as order_date_key,
    coalesce(o.order_date, i.item_created_date)                 as order_date,
    i.item_created_date,
    i.status,
    i.status in ({{ valid_status_list() }})                     as is_valid_sale,
    1                                                           as quantity,
    i.sale_price                                                as net_revenue,
    p.cost                                                      as net_cost,
    i.sale_price - p.cost                                       as net_margin
from items i
left join orders o   on o.order_id    = i.order_id
left join users u    on u.customer_id = i.customer_id
left join products p on p.product_id  = i.product_id
