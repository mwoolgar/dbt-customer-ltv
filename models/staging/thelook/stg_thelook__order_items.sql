-- Items stamped in the future are dropped (see stg_thelook__orders). item_created_date is kept for reference only:
-- items on one order can carry different dates, so order-level logic uses the order's own placed date.
select
    id                  as order_item_id,
    order_id,
    user_id             as customer_id,
    product_id,
    status,
    created_at,
    date(created_at)    as item_created_date,
    sale_price
from {{ source('thelook', 'order_items') }}
where date(created_at) <= current_date()
