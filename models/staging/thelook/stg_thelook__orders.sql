-- The public dataset contains orders stamped a few days in the future (generator artefact).
-- They are not real sales, so anything dated after today is dropped here.
select
    order_id,
    user_id             as customer_id,
    status              as order_status,
    created_at          as order_created_at,
    date(created_at)    as order_date,
    num_of_item
from {{ source('thelook', 'orders') }}
where date(created_at) <= current_date()
