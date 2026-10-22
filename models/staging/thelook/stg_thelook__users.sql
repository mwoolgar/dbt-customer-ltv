-- Personal fields (name, email, address) are deliberately left out. Only what the model needs.
select
    id                  as customer_id,
    traffic_source,
    country,
    created_at          as signed_up_at,
    date(created_at)    as signed_up_date
from {{ source('thelook', 'users') }}
